#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["packaging", "pyyaml", "truststore", "websockets"]
# ///
"""Install a Home Assistant Core or OS release on the Pi through HA's API.

Usage:
  upgrade.py {core,os} --url HA_URL --ssh DEST [--remote-dir PATH] --pin VERSION [--version VERSION]
             [--no-backup] [--no-reboot] [--yes] [--dry-run] [--timeout SECONDS]

The Supervisor installs both Core and the OS. The script calls update.install
on HA's update entity for the component, which hands the install to the
Supervisor, and waits until the Pi runs the release. The steps run in this
order:

1. Pick the release. Core defaults to --pin, the HASS_IMAGE tag that
   hass:check validates against, and refuses a pin older than the running
   release. The OS defaults to the latest release that the Supervisor offers.
   --version overrides both, and can install an older release.
2. Check that HA runs outside recovery and safe mode, that no install runs,
   that HA's config check passes on the Pi's config, and that no deploy holds
   the lock on the Pi. The install restarts HA on that config.
3. Print the plan and ask for confirmation, unless --yes. --dry-run stops
   before the question.
4. Call update.install. Unless --no-backup, HA first saves a backup with the
   settings of its automatic backups, which takes minutes.
5. Wait until the install ends. A Core install restarts HA on the release.
   When the release fails the Supervisor's start check, the Supervisor rolls
   back, so HA runs the old release again and the script fails. An OS install
   writes the release to the spare boot slot, where it waits for a reboot.
6. For the OS, reboot the Pi through hassio.host_reboot, unless --no-reboot,
   and wait until the Pi runs the release. When the release fails to boot,
   the Pi falls back to the old slot, and the script fails.
7. List each automation and script that became unavailable.

HA's OS update entity reports a pending release as installed, so the script
reads the running and the pending OS release from the Supervisor's /os/info,
through HA's supervisor/api WebSocket command.

HASS_TOKEN in the environment holds an admin long-lived access token for --url.
The script exits 0 when the Pi runs the release, including when it already
did, and when --no-reboot leaves an installed OS release pending. It exits 1
on any failure.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
from dataclasses import dataclass

import truststore
from packaging.version import InvalidVersion, Version
from websockets.exceptions import WebSocketException
from websockets.sync.client import connect

import deploy

INSTALL_TIMEOUT = 2 * 60 * 60
"""The default seconds that the backup, the download, a database migration, and the restart or reboot get to finish."""

CALL_SECONDS = 30
"""The seconds to wait on a service call. HA keeps installing when the call times out."""

POLL_SECONDS = 10
"""The seconds between two reads of the Pi's state during the install."""

SETTLE_SECONDS = 5 * 60
"""How long the Pi runs the old release, with no install in progress, before the script calls the install failed.

HA reports a rolled-back Core release only after its startup, and the
Supervisor starts a reboot a few seconds after it accepts one.
"""

OS_SETTLE_SECONDS = 60
"""How long after an OS install ends the script waits for the Supervisor to report the pending release."""

BACKUP, SPECIFIC_VERSION = 8, 2
"""The UpdateEntityFeature bits that the install needs."""


class UpgradeError(Exception):
    """UpgradeError stops the upgrade with a message for the user."""


@dataclass(frozen=True)
class Component:
    name: str
    title: str
    entity: str
    install: str
    """What the Supervisor does after the backup."""


CORE = Component("core", "Home Assistant Core", "update.home_assistant_core_update", "pulls the image and restarts HA on it")
OS = Component(
    "os", "Home Assistant Operating System", "update.home_assistant_operating_system_update", "writes the image to the spare boot slot"
)
COMPONENTS = {c.name: c for c in (CORE, OS)}


def newer(a: str, b: str) -> bool:
    """Return whether release a is newer than release b. A release that does not parse is never newer."""
    try:
        return Version(a) > Version(b)
    except InvalidVersion:
        return False


def os_info(url: str, token: str, timeout: float = 30) -> dict:
    """Return the Supervisor's /os/info through HA's supervisor/api WebSocket command, which needs an admin token."""
    ws_url = re.sub(r"^http", "ws", url.rstrip("/")) + "/api/websocket"
    try:
        with connect(ws_url, open_timeout=timeout, close_timeout=5) as ws:
            json.loads(ws.recv(timeout))  # auth_required
            ws.send(json.dumps({"type": "auth", "access_token": token}))
            if json.loads(ws.recv(timeout)).get("type") != "auth_ok":
                raise UpgradeError("HA's WebSocket API refused HASS_TOKEN")
            ws.send(json.dumps({"id": 1, "type": "supervisor/api", "endpoint": "/os/info", "method": "get"}))
            reply = json.loads(ws.recv(timeout))
    except (OSError, TimeoutError, ValueError, WebSocketException) as err:
        raise UpgradeError(f"cannot read /os/info from the Supervisor: {err}") from err
    if not reply.get("success") or not isinstance(reply.get("result"), dict):
        raise UpgradeError(f"the Supervisor's /os/info failed: {reply.get('error')}")
    return reply["result"]


def read(api: deploy.API, path: str) -> object:
    """Return the GET of path, or None when HA does not answer."""
    try:
        return api.call("GET", path, timeout=10)
    except (urllib.error.URLError, OSError, ValueError):
        return None


def running(api: deploy.API) -> dict | None:
    """Return HA's /api/config while HA runs, and None while it stops, starts, or does not answer."""
    config = read(api, "/api/config")
    return config if isinstance(config, dict) and config.get("state") == "RUNNING" else None


def settled(entity: object) -> bool:
    """Return whether the update entity has loaded and runs no install."""
    return (
        isinstance(entity, dict)
        and entity.get("state") in ("on", "off")
        and not entity.get("attributes", {}).get("in_progress")
    )


def pick(component: Component, args: argparse.Namespace, installed: str, latest: str | None) -> tuple[str, str]:
    """Return the release to install and the source that names it."""
    if args.version:
        return args.version, "VERSION"
    if component is CORE:
        if newer(installed, args.pin):
            raise UpgradeError(
                f"the Pi runs Core {installed}, which is newer than the HASS_IMAGE pin {args.pin}. "
                "Merge the Renovate bump of HASS_IMAGE first, or pass VERSION"
            )
        return args.pin, "the HASS_IMAGE pin"
    if not latest:
        raise UpgradeError("the Supervisor names no latest OS release; pass VERSION")
    return latest, "the latest release that the Supervisor offers"


def call(api: deploy.API, service: str, body: dict[str, object]) -> str | None:
    """Call a service that might outlive the request, and return HA's error when it answered with one."""
    try:
        api.call("POST", f"/api/services/{service.replace('.', '/')}", body, timeout=CALL_SECONDS)
    except urllib.error.HTTPError as err:
        text = err.read().decode(errors="replace")[:500]
        if err.code < 500:
            raise UpgradeError(f"HA refused {service}: {err.code} {text}") from err
        return f"{err.code} {text}"
    except (urllib.error.URLError, OSError):
        pass  # The call timed out, which leaves the service running, or HA stopped.
    return None


def failure(what: str, error: str | None) -> UpgradeError:
    if error:
        what += f". HA answered {error}"
    return UpgradeError(f"{what}. Read the Supervisor log in Settings > System > Logs")


def wait_core(api: deploy.API, target: str, error: str | None, deadline: float) -> None:
    """Wait until HA runs target and the Supervisor's install job has ended."""
    restarted = False
    idle_since: float | None = None
    while time.monotonic() < deadline:
        time.sleep(POLL_SECONDS)
        now = time.monotonic()
        config = running(api)
        if config is None:
            restarted, idle_since = True, None
            continue
        installed = config.get("version")
        if installed == target and (config.get("recovery_mode") or config.get("safe_mode")):
            raise UpgradeError(f"HA runs {target} in recovery or safe mode; read its log")
        # The install job runs until the Supervisor has checked the new
        # release, and it rolls back a release that fails the check.
        if not settled(read(api, f"/api/states/{CORE.entity}")):
            idle_since = None
            continue
        if installed == target:
            return
        idle_since = idle_since or now
        if now - idle_since >= SETTLE_SECONDS:
            if restarted:
                raise failure(f"HA came back on {installed} instead of {target}, so the Supervisor rolled the install back", error)
            raise failure(f"the install ended, and HA still runs {installed}", error)
    raise UpgradeError(f"HA did not run Core {target} in time; check Settings > System > Updates")


def wait_os_install(api: deploy.API, url: str, token: str, target: str, error: str | None, deadline: float) -> None:
    """Wait until the Supervisor reports target as the pending OS release."""
    idle_since: float | None = None
    while time.monotonic() < deadline:
        time.sleep(POLL_SECONDS)
        now = time.monotonic()
        try:
            info = os_info(url, token)
        except UpgradeError:
            idle_since = None
            continue
        if info.get("version_pending") == target:
            return
        if not settled(read(api, f"/api/states/{OS.entity}")):
            idle_since = None
            continue
        idle_since = idle_since or now
        if now - idle_since >= OS_SETTLE_SECONDS:
            raise failure(f"the install ended, and OS {target} is not pending", error)
    raise UpgradeError(f"the Supervisor did not install OS {target} in time; check Settings > System > Updates")


def wait_os_boot(api: deploy.API, url: str, token: str, target: str, error: str | None, deadline: float) -> None:
    """Wait until the Pi runs target with no release pending."""
    rebooted = False
    idle_since: float | None = None
    while time.monotonic() < deadline:
        time.sleep(POLL_SECONDS)
        now = time.monotonic()
        if running(api) is None:
            rebooted, idle_since = True, None
            continue
        try:
            info = os_info(url, token)
        except UpgradeError:
            idle_since = None
            continue
        if info.get("version") == target and not info.get("version_pending"):
            return
        idle_since = idle_since or now
        if now - idle_since >= SETTLE_SECONDS:
            if rebooted:
                raise failure(f"the Pi runs OS {info.get('version')} after the reboot, so it fell back to the old boot slot", error)
            raise failure(f"the Pi did not reboot, and OS {target} still waits for it", error)
    raise UpgradeError(f"the Pi did not boot OS {target} in time; check Settings > System")


def upgrade(args: argparse.Namespace) -> int:
    component = COMPONENTS[args.component]
    token = os.environ.get("HASS_TOKEN", "")
    if not token:
        raise UpgradeError("set HASS_TOKEN to an admin long-lived access token")
    api = deploy.API(args.url, token)

    # 1. Pick the release.
    config = api.get("/api/config")
    entity = api.get(f"/api/states/{component.entity}")
    attributes = entity.get("attributes", {})
    pending = None
    if component is CORE:
        installed, latest = config.get("version"), attributes.get("latest_version")
    else:
        info = os_info(args.url, token)
        installed, pending, latest = info.get("version"), info.get("version_pending"), info.get("version_latest")
    if not installed:
        raise UpgradeError(f"HA names no running {component.title} release")
    target, source = pick(component, args, installed, latest)
    if target == installed:
        print(f"upgrade: the Pi already runs {component.title} {installed}")
        return 0
    staged = component is OS and pending == target
    if staged and not args.reboot:
        print(f"upgrade: OS {target} is installed and activates at the next reboot")
        return 0

    # 2. Check the Pi.
    if config.get("state") != "RUNNING" or config.get("recovery_mode") or config.get("safe_mode"):
        raise UpgradeError(f"HA is {config.get('state')}, or in recovery or safe mode; fix that before an upgrade")
    if attributes.get("in_progress"):
        raise UpgradeError(f"{component.entity} is installing a release already")
    features = attributes.get("supported_features") or 0
    if not staged and args.backup and not features & BACKUP:
        raise UpgradeError(f"{component.entity} cannot back up before the install; pass BACKUP=0")
    if not staged and target != latest and not features & SPECIFIC_VERSION:
        raise UpgradeError(f"{component.entity} installs only its latest release, {latest}")
    check = api.check_config()
    if check["result"] != "valid":
        raise UpgradeError(f"HA's config check fails on the Pi's config, which the upgrade restarts HA on:\n{check.get('errors')}")
    remote = deploy.Remote(args.ssh, args.remote_dir, ["configuration.yaml"])
    if lock := remote.lock_state():
        stamp, age = lock
        raise UpgradeError(
            f"deploy {stamp} has held {deploy.STATE_DIR}/lock on the Pi for {age} s. "
            "Wait for it to finish, or run task hass:deploy, which undoes a dead deploy"
        )

    # 3. Confirm.
    print(f"upgrade: {component.title} {installed} to {target} on {args.url}")
    print(f"  release: {source}")
    if component is CORE and target != args.pin:
        print(f"  WARNING: hass:check validates against the HASS_IMAGE pin {args.pin}, not {target}")
    if latest and target != latest:
        print(f"  note: the latest release that the Supervisor offers is {latest}")
    if newer(installed, target):
        print("  WARNING: this installs an older release; when it fails to start, restore the backup")
    if staged:
        print(f"  install: done earlier; {target} waits in the spare boot slot")
    else:
        print(f"  backup: {'first, with the settings of the automatic backups' if args.backup else 'none'}")
        print(f"  install: the Supervisor {component.install}")
    if component is OS:
        print("  then: reboot the Pi" if args.reboot else "  then: leave the release pending until your next reboot")
    if args.dry_run:
        print("upgrade: dry run, nothing installed")
        return 0
    if not args.yes and not deploy.confirm("Upgrade?"):
        print("upgrade: cancelled")
        return 1

    # 4 to 6. Install, reboot, and wait.
    broken_before = api.broken()
    started = time.monotonic()
    deadline = started + args.timeout
    try:
        if not staged:
            print("upgrade: installing; HA goes offline while it restarts" if component is CORE else "upgrade: installing")
            body: dict[str, object] = {"entity_id": component.entity, "backup": args.backup}
            if features & SPECIFIC_VERSION:
                body["version"] = target
            if error := call(api, "update.install", body):
                print(f"upgrade: update.install answered {error}; waiting to see whether the install continues")
            if component is CORE:
                wait_core(api, target, error, deadline)
            else:
                wait_os_install(api, args.url, token, target, error, deadline)
        if component is OS:
            if not args.reboot:
                print(f"upgrade: OS {target} is installed and activates at the next reboot. Reboot from Settings > System")
                return 0
            print("upgrade: rebooting the Pi")
            if error := call(api, "hassio.host_reboot", {}):
                print(f"upgrade: hassio.host_reboot answered {error}; waiting to see whether the Pi reboots")
            wait_os_boot(api, args.url, token, target, error, deadline)
    except KeyboardInterrupt:
        print("\nupgrade: stopped waiting, but the Supervisor carries on. Check Settings > System > Updates", file=sys.stderr)
        return 1
    print(f"upgrade: the Pi runs {component.title} {target} after {int(time.monotonic() - started) // 60} min")

    # 7. Report what broke.
    if new := sorted(api.broken() - broken_before):
        print(f"upgrade: HA could not load these, see its log: {new}", file=sys.stderr)
        return 1
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="upgrade.py", description=__doc__.split("\n\n")[0])
    parser.add_argument("component", choices=sorted(COMPONENTS))
    parser.add_argument("--url", required=True)
    parser.add_argument("--ssh", metavar="DEST", required=True)
    parser.add_argument("--remote-dir", default="/config")
    parser.add_argument("--pin", required=True)
    parser.add_argument("--version", default="")
    parser.add_argument("--no-backup", dest="backup", action="store_false")
    parser.add_argument("--no-reboot", dest="reboot", action="store_false")
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--timeout", type=float, default=INSTALL_TIMEOUT)
    args = parser.parse_args(argv[1:])
    truststore.inject_into_ssl()
    try:
        return upgrade(args)
    except (UpgradeError, deploy.DeployError) as err:
        print(f"upgrade: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
