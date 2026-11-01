#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["pyyaml", "truststore"]
# ///
"""Deploy a rendered Home Assistant config directory to the Pi over SSH.

Usage:
  deploy.py OUT WORK --ssh DEST [--remote-dir PATH] --url URL [--yes] [--restart] [--dry-run]

OUT is the directory that hass:render wrote. The deploy owns the paths that
livediff.py diffs: configuration.yaml, secrets.example.yaml, .gitignore, and
the package directory. Apart from its own .hass-deploy directory, it never
touches another path on the Pi, such as secrets.yaml, the UI files, .storage,
or custom_components. It keeps every secrets.yaml inside the package
directory. The steps run in this order:

1. Clear a lock that a killed deploy left behind, by restoring that deploy's
   backup. A lock younger than STALE_LOCK_SECONDS means that a deploy is
   running, so the script stops.
2. Read the live copy of the owned paths over SSH, print the diff, and stop
   when nothing changed. Stop with an error when the Pi's secrets.yaml lacks a
   referenced secret, because HA then fails to load the config.
3. Plan the reload, and warn about each change that needs a restart.
4. Ask for confirmation, unless --yes. --dry-run stops before this step.
5. Upload the owned paths in one SSH session. The Pi takes the lock, checks
   that its files still match the diff and that the upload arrived whole,
   saves the old files to a backup tar, and swaps in the new ones.
6. Run HA's config check through the API. An error, or a warning that the
   check before the upload did not report, restores the backup. Any other
   failure from the upload to this point, including Ctrl-C, also restores it.
7. Call homeassistant.reload_all, or homeassistant.restart with --restart, and
   wait for HA to run again.
8. Check that the Pi's owned files match OUT, list each automation and script
   that became unavailable, release the lock, and keep the KEEP_BACKUPS
   newest backups. The first deploy's backup also stays as original.tar.

HASS_TOKEN in the environment holds an admin long-lived access token for --url.
The script exits 0 when the deploy finished or nothing changed, and 1 on any
failure.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import secrets
import shlex
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.request
from pathlib import Path

import truststore
import yaml

import livediff

STATE_DIR = ".hass-deploy"
"""The directory under --remote-dir that holds the lock, the staged upload, and the backups."""

KEEP_BACKUPS = 5
"""The number of backup tars that the Pi keeps under STATE_DIR/backups."""

STALE_LOCK_SECONDS = 30 * 60
"""A lock older than this belongs to a deploy that died, because a live one finishes sooner."""

OWNED_FILES = {"configuration.yaml", "secrets.example.yaml", ".gitignore"}
"""The top-level files that a render can write. Every other owned path is the package directory."""

HA_DIRS = {".storage", ".cloud", "custom_components", "blueprints", "www", "themes", "deps", "tts", "image", "backups"}
"""Directories that HA, HACS, or the Supervisor fill, which the package directory must never be."""

NO_RELOAD_NEEDED = {"http"}
"""Domains whose YAML HA ignores. HA 2026.8 and later keep the HTTP config in .storage."""

RESTART_CORE_KEYS = {
    "latitude", "longitude", "elevation", "name", "radius", "time_zone", "country", "currency",
    "language", "unit_system", "auth_providers", "auth_mfa_modules", "debug",
}
"""Keys of the homeassistant: block that integrations read only at startup or on an event that a reload never fires."""


class DeployError(Exception):
    """DeployError stops the deploy with a message for the user."""


class RemoteError(DeployError):
    """RemoteError is a failed SSH script, with its exit code."""

    def __init__(self, message: str, code: int) -> None:
        super().__init__(message)
        self.code = code


# Exit codes of the upload script that mean it changed nothing.
LOCKED, CHANGED, UNSAFE, INCOMPLETE = 5, 3, 4, 6


def fingerprint(root: Path, names: list[str]) -> str:
    """Return the hash of the `sha256sum` listing of the owned files under root, as the Pi's fp prints it."""
    lines = []
    for name in names:
        path = root / name
        if path.is_file() and not path.is_symlink():
            lines.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {name}")
        elif path.is_dir() and not path.is_symlink():
            files = sorted(
                f"{name}/{f.relative_to(path).as_posix()}"
                for f in path.rglob("*")
                if f.is_file() and not f.is_symlink() and f.name != livediff.SECRETS
            )
            lines += [f"{hashlib.sha256((root / f).read_bytes()).hexdigest()}  {f}" for f in files]
    return hashlib.sha256("".join(line + "\n" for line in lines).encode()).hexdigest()


class Remote:
    """Remote runs the deploy's shell scripts on the Pi over SSH."""

    def __init__(self, dest: str, remote_dir: str, names: list[str]) -> None:
        self.dest = dest
        self.dir = remote_dir
        self.names = names
        self.quoted = " ".join(shlex.quote(n) for n in names)

    def run(self, body: str, stdin: bytes | None = None) -> subprocess.CompletedProcess[bytes]:
        # fp prints the same hash as fingerprint(). unsafe lists the symlinks
        # and hard links that the deploy refuses, because the copy that
        # livediff.py fetches skips them.
        script = f"""
set -eu
cd {shlex.quote(self.dir)}
d={STATE_DIR}
L="$d/lock"
fp() {{
  for p in {self.quoted}; do
    if [ -f "$p" ] && [ ! -L "$p" ]; then sha256sum "$p"
    elif [ -d "$p" ] && [ ! -L "$p" ]; then
      find "$p" -type f ! -name {livediff.SECRETS} | LC_ALL=C sort | while IFS= read -r f; do sha256sum "$f"; done
    fi
  done | sha256sum | cut -d' ' -f1
}}
unsafe() {{
  for p in {self.quoted}; do
    if [ -L "$p" ]; then echo "$p"
    elif [ -d "$p" ]; then find "$p" -type l; find "$p" -type f -links +1
    fi
  done
}}
{body}
"""
        return self.execute(script, stdin)

    def execute(self, script: str, stdin: bytes | None) -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(["ssh", "-o", "BatchMode=yes", self.dest, script], input=stdin, capture_output=True)

    def check(self, result: subprocess.CompletedProcess[bytes], what: str) -> str:
        if result.returncode != 0:
            err = result.stderr.decode(errors="replace").strip()
            raise RemoteError(f"{what} on {self.dest} failed (exit {result.returncode}): {err}", result.returncode)
        return result.stdout.decode().strip()

    def lock_state(self) -> tuple[str, int] | None:
        """Return the stamp and the age in seconds of the lock, or None when no deploy holds it."""
        out = self.check(
            self.run('if [ -d "$L" ]; then echo "$(cat "$L/stamp" 2>/dev/null) $(( $(date +%s) - $(stat -c %Y "$L") ))"; fi'),
            "reading the lock",
        )
        if not out:
            return None
        stamp, _, age = out.rpartition(" ")
        return stamp, int(age)

    def upload(self, stamp: str, archive: bytes, live_fp: str, rendered_fp: str) -> None:
        """Take the lock, back up the old paths, and swap the uploaded ones into place."""
        q = shlex.quote
        body = f"""
mkdir -p "$d/backups"
mkdir "$L" 2>/dev/null || {{ echo "deploy: $L exists, so another deploy holds the lock" >&2; exit {LOCKED}; }}
echo {q(stamp)} > "$L/stamp"
trap 'echo $? > "$L/exit"' EXIT
bad=$(unsafe)
if [ -n "$bad" ]; then echo "deploy: refusing symlinks and hard links:" $bad >&2; exit {UNSAFE}; fi
if [ "$(fp)" != {q(live_fp)} ]; then echo "deploy: the live config changed after the diff" >&2; exit {CHANGED}; fi
n="$d/next-{stamp}"
cat > "$n.tar"
if [ "$(sha256sum "$n.tar" | cut -d' ' -f1)" != {q(hashlib.sha256(archive).hexdigest())} ]; then
  echo "deploy: the upload arrived incomplete" >&2; exit {INCOMPLETE}
fi
mkdir "$n"
tar -xf "$n.tar" -C "$n"
rm -f "$n.tar"
for p in {self.quoted}; do [ -e "$n/$p" ] || {{ echo "deploy: the upload lacks $p" >&2; exit {INCOMPLETE}; }}; done
if [ "$(cd "$n" && fp)" != {q(rendered_fp)} ]; then echo "deploy: the upload does not match the render" >&2; exit {INCOMPLETE}; fi
set --
for p in {self.quoted}; do if [ -e "$p" ]; then set -- "$@" "$p"; fi; done
b="$d/backups/{stamp}.tar"
# BusyBox tar refuses an empty archive, so an empty backup is a zero-byte file.
if [ "$#" -gt 0 ]; then tar -cf "$b" "$@"; else : > "$b"; fi
[ -e "$d/original.tar" ] || cp "$b" "$d/original.tar"
: > "$L/backup-ok"
for p in {self.quoted}; do
  if [ -d "$p" ]; then
    find "$p" -type f -name {livediff.SECRETS} | while IFS= read -r f; do
      mkdir -p "$n/$(dirname "$f")"
      cp -p "$f" "$n/$f"
    done
  fi
done
: > "$L/swapping"
for p in {self.quoted}; do
  if [ -d "$p" ]; then rm -rf "$p"; fi
  mv -f "$n/$p" "$p"
done
rm -rf "$n"
"""
        self.check(self.run(body, archive), "the upload")

    def recover(self, stamp: str) -> str:
        """Undo the deploy that holds the lock with this stamp, and release the lock.

        The script waits up to a minute for that deploy's upload script to end.
        When the swap started, it restores the backup and prints `restored`.
        Otherwise it removes the unused backup and prints `unchanged`.
        """
        body = f"""
[ -d "$L" ] || {{ echo unchanged; exit 0; }}
[ "$(cat "$L/stamp" 2>/dev/null)" = {shlex.quote(stamp)} ] || {{ echo "deploy: $L belongs to another deploy" >&2; exit 7; }}
i=0
while [ ! -e "$L/exit" ] && [ "$i" -lt 60 ]; do sleep 1; i=$((i + 1)); done
b="$d/backups/{stamp}.tar"
if [ -e "$L/swapping" ]; then
  for p in {self.quoted}; do rm -rf "$p"; done
  if [ -s "$b" ]; then tar -xf "$b"; fi
  echo restored
else
  rm -f "$b"
  echo unchanged
fi
rm -rf "$d/next-{stamp}" "$d/next-{stamp}.tar" "$L"
"""
        return self.check(self.run(body), "the recovery")

    def finish(self, stamp: str) -> str:
        """Release the lock, prune old backups, and return the fingerprint of the deployed files."""
        body = f"""
if [ "$(cat "$L/stamp" 2>/dev/null)" = {shlex.quote(stamp)} ]; then rm -rf "$L"; fi
ls -1 "$d/backups" | grep '[.]tar$' | sort -r | tail -n +{KEEP_BACKUPS + 1} | while IFS= read -r f; do rm -f "$d/backups/$f"; done
fp
"""
        return self.check(self.run(body), "the release")

    def restore_command(self, stamp: str) -> str:
        b = f"{STATE_DIR}/backups/{stamp}.tar"
        cmd = f"cd {shlex.quote(self.dir)} && rm -rf {self.quoted} && {{ [ ! -s {b} ] || tar -xf {b}; }}"
        return f"ssh {self.dest} {shlex.quote(cmd)}"


class API:
    """API calls HA's REST API with a bearer token."""

    def __init__(self, url: str, token: str) -> None:
        self.url = url.rstrip("/")
        self.token = token

    def call(self, method: str, path: str, body: object = None, timeout: float = 60) -> object:
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(
            self.url + path,
            data=data,
            method=method,
            headers={"Authorization": f"Bearer {self.token}", "Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=timeout) as response:
            text = response.read().decode()
        return json.loads(text) if text else None

    def get(self, path: str) -> object:
        try:
            return self.call("GET", path)
        except (urllib.error.URLError, OSError, ValueError) as err:
            raise DeployError(f"cannot read {path} from HA: {err}") from err

    def check_config(self) -> dict:
        try:
            result = self.call("POST", "/api/config/core/check_config", timeout=300)
        except (urllib.error.URLError, OSError, ValueError) as err:
            raise DeployError(f"HA's config check failed to run: {err}") from err
        if not isinstance(result, dict) or result.get("result") not in ("valid", "invalid"):
            raise DeployError(f"HA's config check returned {result!r}")
        return result

    def broken(self) -> set[str]:
        """Return the automations and scripts that HA could not load."""
        states = self.get("/api/states")
        return {
            s["entity_id"]
            for s in states
            if s["entity_id"].split(".")[0] in ("automation", "script")
            and s["state"] == "unavailable"
            and not s.get("attributes", {}).get("restored")
        }

    def restart(self, timeout: float = 600) -> None:
        """Restart HA, wait until the old instance stops, then until the new one runs."""
        try:
            self.call("POST", "/api/services/homeassistant/restart", {}, timeout=30)
        except urllib.error.HTTPError as err:
            raise DeployError(f"HA refused the restart: {err.code} {err.read().decode(errors='replace')[:300]}") from err
        except (urllib.error.URLError, OSError):
            pass  # HA drops the connection when it stops.
        deadline = time.monotonic() + timeout
        stopped = False
        while time.monotonic() < deadline:
            try:
                config = self.call("GET", "/api/config", timeout=10)
            except (urllib.error.URLError, OSError, ValueError):
                stopped = True
                time.sleep(5)
                continue
            state = config.get("state") if isinstance(config, dict) else None
            if state != "RUNNING":
                stopped = True
            elif stopped:
                if config.get("recovery_mode") or config.get("safe_mode"):
                    raise DeployError("HA restarted in recovery or safe mode; read its log")
                return
            time.sleep(5)
        raise DeployError(f"HA at {self.url} did not restart within {int(timeout)} s")


def package_tag(out: Path) -> str | None:
    for doc in livediff.load(out / "configuration.yaml"):
        core = doc.get("homeassistant") if isinstance(doc, dict) else None
        node = core.get("packages") if isinstance(core, dict) else None
        if isinstance(node, livediff.Tagged):
            return node.tag
    return None


def check_names(out: Path, names: list[str]) -> str | None:
    """Return the package directory, and fail on an owned name that a render cannot write."""
    pkg = livediff.package_dir(out / "configuration.yaml")
    for name in names:
        if name in OWNED_FILES:
            continue
        if name != pkg or not re.fullmatch(r"[a-z0-9_]+", name) or name in HA_DIRS:
            raise DeployError(f"refusing to own {name!r}; only {sorted(OWNED_FILES)} and a package directory qualify")
    if pkg and package_tag(out) != "!include_dir_named":
        raise DeployError(f"the deploy supports only `packages: !include_dir_named {pkg}`, got {package_tag(out)}")
    return pkg


def domains(root: Path, pkg: str | None) -> dict[str, list[str]]:
    """Map each reload domain in the config under root to the YAML of its entries.

    A list entry that names a `platform`, such as `light: [{platform: group}]`,
    counts under that platform, because the platform's integration reloads it.
    """
    found: dict[str, list[str]] = {}

    def add(domain: str, label: str, value: object) -> None:
        dump = yaml.dump(value, Dumper=livediff.TagDumper, sort_keys=True, width=1 << 16)
        found.setdefault(domain, []).append(f"{label}: {dump}")

    files = [root / "configuration.yaml"]
    if pkg and (root / pkg).is_dir():
        files += sorted(p for p in (root / pkg).rglob("*.yaml") if p.is_file())
    for path in files:
        if not path.is_file():
            continue
        try:
            docs = livediff.load(path)
        except (yaml.YAMLError, UnicodeDecodeError, OSError):
            add(f"<unparsed {path.name}>", path.name, path.read_text(errors="replace"))
            continue
        for doc in docs:
            if not isinstance(doc, dict):
                continue
            for key, value in doc.items():
                # A labelled key, such as `automation raw`, belongs to its first word's domain.
                domain = str(key).split(" ")[0]
                if domain == "homeassistant" and isinstance(value, dict):
                    for core_key, core_value in value.items():
                        add(f"homeassistant.{core_key}", str(key), core_value)
                elif domain == "frontend":
                    add(domain, str(key), {k: v for k, v in (value or {}).items() if k != "themes"} if isinstance(value, dict) or value is None else value)
                elif isinstance(value, list) and value and all(isinstance(v, dict) and "platform" in v for v in value):
                    for entry in value:
                        add(str(entry["platform"]), f"{key} {entry['platform']}", entry)
                else:
                    add(domain, str(key), value)
    return {d: sorted(v) for d, v in found.items()}


def restart_domains(live: Path, rendered: Path, pkg: str | None, reloadable: set[str]) -> tuple[list[str], list[str]]:
    """Return the changed domains, and those that a reload does not apply."""
    before, after = domains(live, pkg), domains(rendered, pkg)
    changed = sorted(d for d in before.keys() | after.keys() if before.get(d) != after.get(d))
    restart = []
    for domain in changed:
        if domain.startswith("homeassistant."):
            if domain.removeprefix("homeassistant.") in RESTART_CORE_KEYS:
                restart.append(domain)
        elif domain == "frontend":
            # Only the themes reload, and domains() leaves them out of frontend.
            restart.append(domain)
        elif domain not in reloadable and domain not in NO_RELOAD_NEEDED:
            restart.append(domain)
    return changed, restart


def confirm(prompt: str) -> bool:
    if not sys.stdin.isatty():
        print("deploy: stdin is not a terminal; pass YES=1 to deploy without asking", file=sys.stderr)
        return False
    return input(f"{prompt} Type yes to continue: ").strip() == "yes"


def recover(remote: Remote, stamp: str) -> None:
    try:
        outcome = remote.recover(stamp)
    except RemoteError as err:
        print(f"deploy: RECOVERY FAILED: {err}", file=sys.stderr)
        print(
            f"deploy: the next deploy undoes this one after its lock is {STALE_LOCK_SECONDS // 60} minutes old. "
            f"To undo it now, check the Pi: when {STATE_DIR}/lock/swapping exists, run "
            f"{remote.restore_command(stamp)}; then remove {STATE_DIR}/lock.",
            file=sys.stderr,
        )
        return
    if outcome == "restored":
        print(f"deploy: restored the previous files from {STATE_DIR}/backups/{stamp}.tar", file=sys.stderr)
    else:
        print("deploy: the Pi's files did not change", file=sys.stderr)


def deploy(args: argparse.Namespace) -> int:
    out: Path = args.out
    if not (out / "configuration.yaml").is_file():
        raise DeployError(f"{out} has no configuration.yaml; run hass:render first")
    if any(p.name == livediff.SECRETS for p in out.rglob("*")):
        raise DeployError(f"{out} holds a {livediff.SECRETS}, which the deploy never uploads")
    token = os.environ.get("HASS_TOKEN", "")
    if not token:
        raise DeployError("set HASS_TOKEN to an admin long-lived access token")
    api = API(args.url, token)
    target = f"{args.ssh}:{args.remote_dir}"

    live, rendered, names = livediff.prepare(out, args.work)
    pkg = check_names(out, names)
    remote = Remote(args.ssh, args.remote_dir, names)

    # 1. Clear a stale lock.
    if lock := remote.lock_state():
        stamp, age = lock
        if age < STALE_LOCK_SECONDS:
            raise DeployError(
                f"deploy {stamp} has held {STATE_DIR}/lock on the Pi for {age} s. Wait for it, or, when no deploy "
                f"runs, remove the lock with: ssh {args.ssh} 'rm -rf {args.remote_dir}/{STATE_DIR}/lock'"
            )
        print(f"deploy: deploy {stamp} left its lock {age} s ago; undoing it first")
        recover(remote, stamp)

    # 2. Diff.
    declared = livediff.declared_secrets(out)
    checkable = [s for s in declared if livediff.CHECKABLE_SECRET.match(s)]
    unchecked = sorted(set(declared) - set(checkable))
    missing = livediff.fetch_ssh(args.ssh, args.remote_dir, names, checkable, live)
    changes = livediff.show_diff(args.work, target)
    if changes is None:
        return 1
    if missing:
        raise DeployError(f"add these secrets to the Pi's {livediff.SECRETS} before you deploy: {missing}")
    if unchecked:
        print(f"deploy: check these secret names by hand, because the check cannot match their characters: {unchecked}")
    if not changes:
        print("deploy: nothing to deploy")
        return 0

    # 3. Plan the reload.
    services = api.get("/api/services")
    reloadable = {s["domain"] for s in services if "reload" in s.get("services", {})}
    changed, restart = restart_domains(live, rendered, pkg, reloadable)
    print(f"\ndeploy: {', '.join(names)} to {target}")
    print(f"  changed: {', '.join(changed) or 'nothing HA reads'}")
    print("  then restart HA" if args.restart else "  then reload all YAML through homeassistant.reload_all")
    if restart and not args.restart:
        print(f"  WARNING: a reload does not apply {restart}; rerun with RESTART=1, or restart HA after the deploy")

    # 4. Confirm.
    if args.dry_run:
        print("deploy: dry run, nothing uploaded")
        return 0
    if not args.yes and not confirm("Deploy?"):
        print("deploy: cancelled")
        return 1

    baseline = api.check_config()
    broken_before = api.broken()
    archive = io.BytesIO()
    # BusyBox tar on the Pi reads the GNU format, including its long names.
    with tarfile.open(fileobj=archive, mode="w", format=tarfile.GNU_FORMAT) as tar:
        for name in names:
            tar.add(rendered / name, arcname=name, filter=_normalize)
    stamp = time.strftime("%Y%m%dT%H%M%S", time.gmtime()) + "-" + secrets.token_hex(3)

    # 5 and 6. Upload and check, and undo both on any failure.
    try:
        remote.upload(stamp, archive.getvalue(), fingerprint(live, names), fingerprint(rendered, names))
        print(f"deploy: uploaded; the previous files are in {STATE_DIR}/backups/{stamp}.tar")
        check = api.check_config()
        for kind in ("errors", "warnings"):
            if check.get(kind):
                print(f"deploy: HA's config check reports {kind}:\n{check[kind]}", file=sys.stderr)
        if check["result"] != "valid":
            raise DeployError("HA rejected the uploaded config")
        if check.get("warnings") and check.get("warnings") != baseline.get("warnings"):
            raise DeployError("the uploaded config adds config check warnings")
    except RemoteError as err:
        if err.code != LOCKED:
            recover(remote, stamp)
        raise
    except BaseException:
        recover(remote, stamp)
        raise

    # 7. Reload or restart. The files passed the check, so a failure here
    # leaves them in place.
    try:
        if args.restart:
            api.restart()
            print("deploy: HA restarted")
        else:
            try:
                api.call("POST", "/api/services/homeassistant/reload_all", {}, timeout=300)
            except urllib.error.HTTPError as err:
                raise DeployError(f"reload_all failed: {err.code} {err.read().decode(errors='replace')[:500]}") from err
            except (urllib.error.URLError, OSError) as err:
                raise DeployError(f"reload_all failed: {err}") from err
            print("deploy: HA reloaded the YAML config")
    except DeployError as err:
        remote.finish(stamp)
        raise DeployError(f"{err}. The new files stay on the Pi; to restore the old ones, run: {remote.restore_command(stamp)}") from err

    # 8. Verify and release.
    status = 0
    if remote.finish(stamp) != fingerprint(rendered, names):
        print(f"deploy: the files on {target} do not match the render; run task hass:diff", file=sys.stderr)
        status = 1
    if new := sorted(api.broken() - broken_before):
        print(f"deploy: HA could not load these, see its log: {new}", file=sys.stderr)
        status = 1
    if restart and not args.restart:
        print(f"deploy: restart HA to apply {restart}")
    print(f"deploy: to undo this deploy, run: {remote.restore_command(stamp)}")
    if status == 0:
        print(f"deploy: done; {target} matches the render")
    return status


def _normalize(member: tarfile.TarInfo) -> tarfile.TarInfo:
    member.uid = member.gid = 0
    member.uname = member.gname = "root"
    member.mode = 0o755 if member.isdir() else 0o644
    return member


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="deploy.py", description=__doc__.split("\n\n")[0])
    parser.add_argument("out", type=Path)
    parser.add_argument("work", type=Path)
    parser.add_argument("--ssh", metavar="DEST", required=True)
    parser.add_argument("--remote-dir", default="/config")
    parser.add_argument("--url", required=True)
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--restart", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv[1:])
    truststore.inject_into_ssl()
    try:
        return deploy(args)
    except (DeployError, SystemExit) as err:
        if str(err):
            print(f"deploy: {err}" if not str(err).startswith(("deploy:", "livediff:")) else str(err), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
