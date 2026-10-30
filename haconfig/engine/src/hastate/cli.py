"""The hastate command: plan, apply, and import haconfig state.

Usage:
  hastate plan   --state FILE [--url URL]
  hastate apply  --state FILE [--url URL] [--yes]
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
from pathlib import Path
from typing import Any

from hastate.apply import ApplyError, apply
from hastate.client import AuthError, Client, HAError
from hastate.kclgen import generate
from hastate.live import read_live
from hastate.plan import StateError, check_format, plan
from hastate.report import print_plan

DEFAULT_URL = "https://hass.cin.macro.network"


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
        result = plan(desired, await read_live(client, desired))
    print_plan(result, args.url)
    return 1 if result.problems else 0


async def cmd_apply(args: argparse.Namespace) -> int:
    desired = load_state(args.state)
    async with Client(args.url, token()) as client:
        result = plan(desired, await read_live(client, desired))
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
            again = plan(desired, await read_live(client, desired))
            if again.fingerprint() != result.fingerprint():
                print("\nerror: the live state changed after the plan; run the apply again to see the new plan", file=sys.stderr)
                return 1
        print("\nApplying:")
        try:
            await apply(client, result)
        except ApplyError as err:
            print(f"\nerror: {err}", file=sys.stderr)
            print(f"{len(err.done)} steps finished before the failure. Run the plan again to see what remains.", file=sys.stderr)
            return 1
        after = plan(desired, await read_live(client, desired))
    if after.actions or after.problems:
        print("\nThe apply finished, but the plan still shows changes:", file=sys.stderr)
        print_plan(after, args.url, sys.stderr)
        return 1
    print(f"\nApply complete: {len(result.actions)} changes applied, and a new plan shows no changes.")
    return 0


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
    i = sub.add_parser("import", help="write a KCL state file from the live registries")
    i.add_argument("--out", type=Path, required=True)
    i.add_argument("--variable", default="hass_state")
    i.add_argument("--force", action="store_true", help="overwrite OUT")
    args = parser.parse_args(argv)

    command = {"plan": cmd_plan, "apply": cmd_apply, "import": cmd_import}[args.command]
    try:
        return asyncio.run(command(args))
    except (StateError, AuthError, HAError, OSError, json.JSONDecodeError, TimeoutError) as err:
        print(f"error: {err}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
