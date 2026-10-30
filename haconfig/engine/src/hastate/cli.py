"""The hastate command: plan, apply, and import haconfig state.

Usage:
  hastate plan   --state FILE [--url URL]
  hastate apply  --state FILE [--url URL] [--yes] [--restart]
  hastate import --out FILE [--url URL] [--force]

The token comes from the HASS_TOKEN environment variable, and the URL from
--url or HASS_URL. plan exits 0 when it can plan, whether or not it finds
changes, and 1 when the plan has problems or the engine cannot read HA. apply asks for
confirmation unless --yes is set, then plans again after the apply and exits 1
when changes remain.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any

from websockets.exceptions import WebSocketException

from hastate.apply import ApplyError, apply
from hastate.client import AuthError, Client, HAError
from hastate.kclgen import generate
from hastate.live import read_live
from hastate import apps, hacs, http
from hastate.plan import Plan, StateError, check_format, plan
from hastate.report import print_plan

DEFAULT_URL = "https://hass.cin.macro.network"

CONNECTION_ERRORS = (WebSocketException, ConnectionError)
"""The errors of a connection that HA closed or dropped, such as during a restart."""


def load_state(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise StateError(f"{path} does not exist; set HomeAssistant.state in the module and render it")
    desired = json.loads(path.read_text())
    check_format(desired)
    return desired


def token() -> str:
    value = os.environ.get("HASS_TOKEN", "").strip()
    if not value:
        raise AuthError("HASS_TOKEN is not set; export it, or run the task through `doppler run -p <project> -c <config> --`")
    return value


async def cmd_plan(args: argparse.Namespace) -> int:
    desired = load_state(args.state)
    async with Client(args.url, token()) as client:
        result = plan(desired, await read_live(client, desired), args.url)
    print_plan(result, args.url)
    if hacs.restart_needed(result.actions):
        print("The apply changes integration code, which HA loads only when it starts; pass --restart to apply, or restart HA after it.")
    return 1 if result.problems else 0


async def cmd_apply(args: argparse.Namespace) -> int:
    desired = load_state(args.state)
    client = await Client(args.url, token()).__aenter__()
    try:
        result = plan(desired, await read_live(client, desired), args.url)
        print_plan(result, args.url)
        if result.problems:
            return 1
        if not result.actions:
            return 0
        if not args.yes:
            if not await confirm(len(result.actions), args.url):
                print("Apply cancelled.")
                return 1
            # HA might have changed while the prompt waited, so the apply
            # runs only the plan that you confirmed.
            again = plan(desired, await read_live(client, desired), args.url)
            if again.problems or again.fingerprint() != result.fingerprint():
                print("\nerror: the live state changed after the plan; run the apply again to see the new plan", file=sys.stderr)
                print_plan(again, args.url, sys.stderr)
                return 1
        print("\nApplying:")
        # The HTTP change restarts HA, so it runs after every other step,
        # and the apply continues on the connection to the new instance.
        http_change = next((c for c in result.actions if c.collection == http.HTTP), None)
        # A new HACS runs only after HA restarts, and a later download might
        # need it, so with --restart the apply restarts HA between them.
        later: list[Any] = []
        if args.restart and hacs.self_update(result.actions):
            later = [c for c in result.actions if c.collection == hacs.HACS and c.key.lower() != hacs.SELF]
        held = {id(c) for c in later} | {id(http_change)}
        first = Plan(result.ha_version, [c for c in result.changes if id(c) not in held])
        restart_due = hacs.restart_needed(first.actions)
        finished: list[str] = []
        try:
            finished += await apply(client, first)
            if later:
                client = await restart(client, desired, print)
                finished.append("restart HA")
                finished += await apply(client, Plan(result.ha_version, later))
                restart_due = hacs.restart_needed(later)
            if http_change is not None:
                client = await http.apply_http(client, http_change, token(), print)
                await wait_ready(client, desired, print)
                # HA restarted after every other step, so it runs the new code.
                restart_due = False
            if args.restart and restart_due:
                client = await restart(client, desired, print)
                restart_due = False
        except ApplyError as err:
            print(f"\nerror: {err}", file=sys.stderr)
            print(f"{len(finished) + len(err.done)} steps finished before the failure. Run the plan again to see what remains.", file=sys.stderr)
            return 1
        except (RuntimeError, TimeoutError, HAError, *CONNECTION_ERRORS) as err:
            print(f"\nerror: {err}", file=sys.stderr)
            return 1
        after = plan(desired, await read_live(client, desired), client.url)
    finally:
        await client.__aexit__(None, None, None)
    if after.actions or after.problems:
        print("\nThe apply finished, but the plan still shows changes:", file=sys.stderr)
        print_plan(after, client.url, sys.stderr)
        return 1
    print(f"\nApply complete: {len(result.actions)} changes applied, and a new plan shows no changes.")
    if restart_due:
        print("Restart HA to load the new integration code, or apply with --restart next time.")
    return 0


READY_TIMEOUT = 600.0
"""The seconds HA gets to finish starting after a restart. A Pi with many integrations takes minutes."""


async def wait_ready(client: Client, desired: dict[str, Any], log: Callable[[str], None], timeout: float = READY_TIMEOUT) -> None:
    """Wait until HA finishes starting and each API that DESIRED manages answers.

    HA answers on the WebSocket API early in its boot, before it loads the
    Supervisor integration and HACS, so a plan right after a restart would
    report them missing. Once HA runs, an unknown command means that HA has
    no Supervisor or no HACS, and the plan reports that.
    """
    loop = asyncio.get_running_loop()
    deadline = loop.time() + timeout

    async def until(name: str, ready: Callable[[], Awaitable[bool]]) -> None:
        while not await ready():
            if loop.time() > deadline:
                raise TimeoutError(f"{name} did not finish starting within {int(timeout)}s")
            await asyncio.sleep(3)

    async def running() -> bool:
        return (await client.call("get_config")).get("state") == "RUNNING"

    async def supervisor() -> bool:
        try:
            await client.supervisor("get", "/supervisor/ping", timeout=10)
        except HAError as err:
            return err.code == "unknown_command"
        return True

    async def hacs_ready() -> bool:
        try:
            info = await client.call("hacs/info")
        except HAError as err:
            return err.code == "unknown_command"
        return info.get("stage") in hacs.READY_STAGES

    await until("HA", running)
    if apps.APPS in desired or apps.REPOSITORIES in desired:
        await until("The Supervisor", supervisor)
    if hacs.HACS in desired:
        await until("HACS", hacs_ready)
    log("  HA is running")


async def restart(client: Client, desired: dict[str, Any], log: Callable[[str], None]) -> Client:
    """Restart HA and return a client connected to the new instance once HA runs again."""
    log("  restarting HA")
    try:
        await client.call("call_service", domain="homeassistant", service="restart", wait=60)
    except (TimeoutError, *CONNECTION_ERRORS):
        # Under the Supervisor, HA closes the connection before it answers.
        pass
    if not await client.wait_closed(timeout=300):
        raise RuntimeError("HA did not restart; check its log")
    new = await http.reconnect([client.url], token(), timeout=600, log=log)
    try:
        await wait_ready(new, desired, log)
    except BaseException:
        await new.__aexit__(None, None, None)
        raise
    return new


async def confirm(count: int, url: str) -> bool:
    """Ask on the terminal. The prompt runs in a thread, so the event loop keeps answering HA's heartbeats."""
    if not sys.stdin.isatty():
        print("\nerror: apply needs a terminal to confirm, or --yes", file=sys.stderr)
        return False
    answer = await asyncio.to_thread(input, f"\nApply {count} changes to {url}? Only 'yes' applies them: ")
    return answer.strip() == "yes"


async def cmd_import(args: argparse.Namespace) -> int:
    if args.out.exists() and not args.force:
        print(f"error: {args.out} exists; pass --force to overwrite it", file=sys.stderr)
        return 1
    async with Client(args.url, token()) as client:
        live = await read_live(client, None)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(generate(live, args.url, args.variable))
    print(f"wrote {args.out}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="hastate", description=__doc__.split("\n\n")[0])
    parser.add_argument("--url", default=os.environ.get("HASS_URL") or DEFAULT_URL)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("plan", help="show the changes that apply would make")
    p.add_argument("--state", type=Path, required=True)
    a = sub.add_parser("apply", help="apply the changes after a confirmation")
    a.add_argument("--state", type=Path, required=True)
    a.add_argument("--yes", action="store_true", help="apply without asking")
    a.add_argument("--restart", action="store_true", help="restart HA after HACS changes integration code")
    i = sub.add_parser("import", help="write a KCL state file from the live registries")
    i.add_argument("--out", type=Path, required=True)
    i.add_argument("--variable", default="hass_state")
    i.add_argument("--force", action="store_true", help="overwrite OUT")
    args = parser.parse_args(argv)

    command = {"plan": cmd_plan, "apply": cmd_apply, "import": cmd_import}[args.command]
    try:
        return asyncio.run(command(args))
    except (StateError, AuthError, HAError, OSError, json.JSONDecodeError, TimeoutError, *CONNECTION_ERRORS) as err:
        print(f"error: {err}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
