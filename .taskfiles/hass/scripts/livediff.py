#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["pyyaml"]
# ///
"""Diff a rendered Home Assistant config directory against the live config.

Usage:
  livediff.py [--semantic] OUT WORK --ssh DEST [--remote-dir PATH]
  livediff.py [--semantic] OUT WORK --live-dir PATH

OUT is the directory that hass:render wrote. The script copies the live copy
of every top-level path that OUT holds into WORK/live, together with the
package directory that OUT/configuration.yaml loads under `homeassistant:
packages:`. It copies OUT into WORK/rendered and prints `git diff --no-index`
between the two. A path in OUT that the live config lacks shows as a new file.
A file that only the live config holds in the package directory shows as
deleted, and hass:deploy removes it, because HA loads every file in that
directory. Other directories, such as a themes directory that HACS fills, stay
out of the diff.

--ssh reads the live config over one SSH connection with tar, from
--remote-dir (default /config). --live-dir reads it from a local directory,
such as a Samba mount of the config share. The script never writes to the
live config, and it skips symlinks and every secrets.yaml.

The script then checks that a secrets.yaml in the live config defines each
secret name in OUT/secrets.example.yaml. Over SSH, the Pi tests each declared
name and returns only the names it lacks, so no secret value and no other
secret name leaves the Pi. With --live-dir, the script parses each
secrets.yaml through the mount and keeps only its keys.

--semantic parses both copies of every YAML file and re-dumps it with sorted
keys, no comments, and no anchors before the diff, so the diff shows only
changes that HA sees. HA tags such as !secret stay tags. A file that fails to
parse is diffed as text.

The script exits 0 when the diff ran, whether or not the trees differ, and 1
when it cannot read the live config.
"""

from __future__ import annotations

import argparse
import io
import os
import re
import shlex
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path

import yaml

SECRETS = "secrets.yaml"
"""HA's secrets file name. The script never copies a file with this name."""

CHECKABLE_SECRET = re.compile(r"^[A-Za-z0-9_.-]+$")
"""Secret names that the remote check can match without shell or regex escapes."""


class Tagged:
    """Tagged keeps a custom YAML tag and its scalar value through a re-dump."""

    def __init__(self, tag: str, value: str) -> None:
        self.tag = tag
        self.value = value


class TagLoader(yaml.SafeLoader):
    """TagLoader reads HA's custom tags as Tagged values instead of failing."""


def _construct_tagged(loader: TagLoader, suffix: str, node: yaml.Node) -> Tagged:
    value = loader.construct_scalar(node) if isinstance(node, yaml.ScalarNode) else repr(node.value)
    return Tagged("!" + suffix, str(value))


TagLoader.add_multi_constructor("!", _construct_tagged)


class TagDumper(yaml.SafeDumper):
    """TagDumper writes Tagged values back with their tag, and never writes anchors."""

    def ignore_aliases(self, data: object) -> bool:
        return True


TagDumper.add_representer(Tagged, lambda dumper, data: dumper.represent_scalar(data.tag, data.value))


def load(path: Path) -> list[object]:
    return list(yaml.load_all(path.read_text(encoding="utf-8-sig"), Loader=TagLoader))


def normalize(path: Path) -> None:
    """Rewrite one YAML file in place with sorted keys and no comments."""
    try:
        docs = load(path)
    except (yaml.YAMLError, UnicodeDecodeError, OSError) as err:
        print(f"livediff: {path.name} does not parse, diffing it as text: {err}", file=sys.stderr)
        return
    path.write_text(
        yaml.dump_all(docs, Dumper=TagDumper, sort_keys=True, default_flow_style=False, allow_unicode=True, width=1 << 16)
    )


def package_dir(config: Path) -> str | None:
    """Return the top-level directory that config loads under `homeassistant: packages:`."""
    for doc in load(config):
        core = doc.get("homeassistant") if isinstance(doc, dict) else None
        node = core.get("packages") if isinstance(core, dict) else None
        if isinstance(node, Tagged) and node.tag.startswith("!include_dir_"):
            path = Path(node.value.strip())
            if path.parts and not path.is_absolute() and path.parts[0] not in (".", ".."):
                return path.parts[0]
    return None


def managed_names(out: Path) -> list[str]:
    """Return the top-level paths that the render owns: every path in OUT and the package directory.

    A package directory that the render leaves empty still exists on the Pi,
    so it counts even when OUT lacks it.
    """
    names = {p.name for p in out.iterdir()}
    if pkg := package_dir(out / "configuration.yaml"):
        names.add(pkg)
    return sorted(names)


def prepare(out: Path, work: Path) -> tuple[Path, Path, list[str]]:
    """Copy OUT into WORK/rendered next to an empty WORK/live, and return both and the managed names."""
    live, rendered = work / "live", work / "rendered"
    shutil.rmtree(work, ignore_errors=True)
    live.mkdir(parents=True)
    shutil.copytree(out, rendered)
    names = managed_names(out)
    for name in names:
        if not (rendered / name).exists():
            (rendered / name).mkdir()
    return live, rendered, names


def show_diff(work: Path, source_name: str) -> bool | None:
    """Print the diff from WORK/live to WORK/rendered, and return whether they differ, or None on error."""
    diff = ["git", "--no-pager", "-c", "core.quotePath=false", "diff", "--no-index", "--no-prefix", "--color=auto"]
    stat = subprocess.run([*diff, "--stat", "--", "live", "rendered"], cwd=work, capture_output=True, text=True)
    if stat.returncode not in (0, 1):
        sys.stderr.write(stat.stderr)
        return None
    if stat.returncode == 0:
        print(f"no changes against {source_name}")
        return False
    print(f"changes against {source_name}:")
    sys.stdout.write(stat.stdout)
    sys.stdout.flush()
    subprocess.run([*diff, "--", "live", "rendered"], cwd=work)
    return True


def _member_filter(member: tarfile.TarInfo, dest: str) -> tarfile.TarInfo | None:
    """Skip links and secrets files, then apply tarfile's data filter."""
    if member.issym() or member.islnk():
        print(f"livediff: skipping link {member.name}", file=sys.stderr)
        return None
    if Path(member.name).name == SECRETS:
        return None
    return tarfile.data_filter(member, dest)


def fetch_ssh(dest: str, remote_dir: str, names: list[str], secrets: list[str], live: Path) -> list[str]:
    """Copy the named paths over SSH, and return the declared secrets that the Pi lacks."""
    quoted = " ".join(shlex.quote(n) for n in names)
    checks = " ".join(shlex.quote(s) for s in secrets)
    # One remote script, so the user authenticates once. Its first line names
    # the missing secrets, and the tar archive follows. Each check greps the
    # root secrets.yaml and every secrets.yaml under the fetched directories,
    # and matches an optional BOM, optional quotes, and a colon after the name.
    script = f"""
cd {shlex.quote(remote_dir)} || exit 1
bom=$(printf '\\357\\273\\277')
files=$(find . -maxdepth 1 -name {SECRETS} -type f; for p in {quoted}; do [ -d "$p" ] && find "$p" -name {SECRETS} -type f; done)
printf 'missing:'
for s in {checks}; do
  e=$(printf '%s' "$s" | sed 's/[.]/[.]/g')
  found=
  for f in $files; do grep -qE "^($bom)?[\\"']?$e[\\"']?[[:space:]]*:" "$f" && found=1 && break; done
  [ -n "$found" ] || printf ' %s' "$s"
done
printf '\\n'
set --
for p in {quoted}; do [ -e "$p" ] && [ ! -L "$p" ] && set -- "$@" "$p"; done
[ "$#" -gt 0 ] && exec tar --exclude={SECRETS} -cf - "$@"
exit 0
"""
    result = subprocess.run(["ssh", "-o", "BatchMode=yes", dest, script], capture_output=True)
    if result.returncode != 0:
        sys.stderr.write(result.stderr.decode(errors="replace"))
        raise SystemExit(f"livediff: cannot read {remote_dir} on {dest} (exit {result.returncode})")
    header, _, archive = result.stdout.partition(b"\n")
    if not header.startswith(b"missing:"):
        raise SystemExit(f"livediff: unexpected output from {dest}: {header[:80]!r}")
    if archive:
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            tar.extractall(live, filter=_member_filter)
    return header.decode().removeprefix("missing:").split()


def _ignore(directory: str, entries: list[str]) -> set[str]:
    links = {e for e in entries if os.path.islink(os.path.join(directory, e))}
    for e in sorted(links):
        print(f"livediff: skipping link {os.path.join(directory, e)}", file=sys.stderr)
    return links | {e for e in entries if e == SECRETS}


def fetch_local(src: Path, names: list[str], secrets: list[str], live: Path) -> list[str]:
    """Copy the named paths from a local live config, and return the declared secrets it lacks."""
    if not src.is_dir():
        raise SystemExit(f"livediff: {src} is not a directory")
    files = [src / SECRETS]
    for name in names:
        path = src / name
        if path.is_symlink():
            print(f"livediff: skipping link {name}", file=sys.stderr)
        elif path.is_dir():
            shutil.copytree(path, live / name, ignore=_ignore)
            files += [f for f in path.rglob(SECRETS) if not f.is_symlink()]
        elif path.is_file() and name != SECRETS:
            shutil.copy2(path, live / name)
    defined: set[str] = set()
    for f in files:
        if not f.is_file():
            continue
        try:
            data = yaml.load(f.read_text(encoding="utf-8-sig"), Loader=TagLoader)
        except (yaml.YAMLError, UnicodeDecodeError, OSError) as err:
            print(f"livediff: cannot parse {f.relative_to(src)}: {err}", file=sys.stderr)
            continue
        if isinstance(data, dict):
            defined.update(str(k) for k in data)
    return [s for s in secrets if s not in defined]


def declared_secrets(out: Path) -> list[str]:
    example = out / "secrets.example.yaml"
    if not example.is_file():
        return []
    data = yaml.load(example.read_text(), Loader=TagLoader) or {}
    return sorted(str(k) for k in data) if isinstance(data, dict) else []


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="livediff.py", description=__doc__.split("\n\n")[0])
    parser.add_argument("out", type=Path)
    parser.add_argument("work", type=Path)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--ssh", metavar="DEST")
    source.add_argument("--live-dir", type=Path)
    parser.add_argument("--remote-dir", default="/config")
    parser.add_argument("--semantic", action="store_true")
    args = parser.parse_args(argv[1:])

    out: Path = args.out
    if not (out / "configuration.yaml").is_file():
        print(f"livediff: {out} has no configuration.yaml; run hass:render first", file=sys.stderr)
        return 1

    work: Path = args.work
    live, rendered, names = prepare(out, work)

    declared = declared_secrets(out)
    checkable = [s for s in declared if CHECKABLE_SECRET.match(s)]
    unchecked = sorted(set(declared) - set(checkable))
    try:
        if args.ssh:
            source_name = f"{args.ssh}:{args.remote_dir}"
            missing = fetch_ssh(args.ssh, args.remote_dir, names, checkable, live)
        else:
            source_name = str(args.live_dir)
            missing = fetch_local(args.live_dir, names, checkable, live)
    except SystemExit as err:
        print(err, file=sys.stderr)
        return 1

    if args.semantic:
        for tree in (live, rendered):
            for path in sorted(tree.rglob("*.yaml")):
                if not path.is_symlink():
                    normalize(path)

    if show_diff(work, source_name) is None:
        return 1

    # The warnings print last, so they stay on screen after a long diff.
    if missing:
        print(f"WARNING: no live secrets.yaml defines these referenced secrets: {missing}")
    if unchecked:
        print(f"WARNING: check these secret names by hand, because the check cannot match their characters: {unchecked}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
