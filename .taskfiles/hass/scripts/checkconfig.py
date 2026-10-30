#!/usr/bin/env python3
"""Gate a staged Home Assistant config directory on Home Assistant's check_config.

Usage: checkconfig.py [--catalog CATALOG] IMAGE STAGE

Runs ``python3 -m homeassistant --script check_config --json`` from IMAGE in
Docker, with STAGE mounted at /config and networking disabled. check_config
exits 0 and reports zero errors for an invalid automation, script, or template
entity, because Home Assistant reports those only as ERROR log lines. The gate
therefore fails when the exit code is not zero, when total_errors or
total_warnings in the JSON report is not zero, or when a line on stdout or
stderr starts with ERROR: or CRITICAL:.

HA checks that every certificate path in ``http`` names an existing file.
The script mounts a read-only /ssl that holds an empty placeholder for each
``/ssl/<file>`` path that a YAML file in STAGE references, because the Pi's
certificates must never leave the Pi.

The script prints WARNING: lines as notes and does not fail on them, because
Home Assistant releases add benign warnings.

With --catalog, the script reads HA_VERSION from that generated catalog.k file
and prints a note when it differs from the IMAGE tag. A Renovate bump of the
image does not regenerate the catalog, so the note tells the reviewer to run
``task hass:gen``.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

FAIL_LINE = re.compile(r"^(ERROR|CRITICAL):")
NOTE_LINE = re.compile(r"^WARNING:")
SSL_PATH = re.compile(r"/ssl/([A-Za-z0-9_.-]+)")
CATALOG_VERSION = re.compile(r'^HA_VERSION\s*=\s*"([^"]+)"', re.MULTILINE)


def ssl_names(stage: Path) -> set[str]:
    """Return the file names under /ssl that the YAML files in STAGE reference."""
    names: set[str] = set()
    for path in stage.rglob("*.yaml"):
        names.update(SSL_PATH.findall(path.read_text(errors="replace")))
    return names


def run_check(image: str, stage: Path) -> subprocess.CompletedProcess[str]:
    """Run check_config from IMAGE against STAGE and capture both streams."""
    with tempfile.TemporaryDirectory(prefix="hass-ssl-") as ssl:
        for name in ssl_names(stage):
            (Path(ssl) / name).touch()
        return subprocess.run(
            [
                "docker", "run", "--rm", "--network", "none",
                "-v", f"{stage.resolve()}:/config",
                "-v", f"{ssl}:/ssl:ro",
                "--entrypoint", "python3",
                image,
                "-m", "homeassistant", "--script", "check_config", "-c", "/config", "--json",
            ],
            capture_output=True,
            text=True,
            check=False,
        )


def parse_report(stdout: str) -> dict | None:
    """Return the JSON report from check_config's stdout, or None when it has none.

    The report starts on the first line that holds only ``{``. Log lines can
    precede it on the same stream.
    """
    lines = stdout.splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.strip() == "{":
            try:
                report, _ = json.JSONDecoder().raw_decode("".join(lines[index:]))
            except json.JSONDecodeError:
                return None
            return report if isinstance(report, dict) else None
    return None


def catalog_note(catalog: Path, image: str) -> str | None:
    """Return a note when the catalog's HA_VERSION differs from the IMAGE tag."""
    tag = image.rsplit(":", 1)[1] if ":" in image.rsplit("/", 1)[-1] else ""
    match = CATALOG_VERSION.search(catalog.read_text()) if catalog.is_file() else None
    if match is None:
        return f"note: {catalog} has no HA_VERSION; run task hass:gen"
    if tag and match.group(1) != tag:
        return f"note: catalog is for Home Assistant {match.group(1)} but the image is {tag}; run task hass:gen"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Gate a staged config directory on check_config.")
    parser.add_argument("--catalog", type=Path, help="generated catalog.k whose HA_VERSION should match IMAGE")
    parser.add_argument("image", help="Home Assistant container image, pinned by tag")
    parser.add_argument("stage", type=Path, help="config directory prepared by stage.py")
    args = parser.parse_args()

    if not (args.stage / "configuration.yaml").is_file():
        print(f"checkconfig: {args.stage} has no configuration.yaml; run stage.py first", file=sys.stderr)
        return 1

    if args.catalog is not None:
        note = catalog_note(args.catalog, args.image)
        if note:
            print(note)

    try:
        proc = run_check(args.image, args.stage)
    except FileNotFoundError:
        print("checkconfig: docker is not on PATH", file=sys.stderr)
        return 1

    lines = proc.stdout.splitlines() + proc.stderr.splitlines()
    failures = [line for line in lines if FAIL_LINE.match(line)]
    for line in lines:
        if NOTE_LINE.match(line):
            print(f"note: {line}")
    for line in failures:
        print(f"fail: {line}")

    report = parse_report(proc.stdout)
    if report is None:
        print("fail: check_config printed no JSON report", file=sys.stderr)
        print(proc.stdout + proc.stderr, file=sys.stderr)
        return 1

    errors = report.get("total_errors", 0)
    warnings = report.get("total_warnings", 0)
    print(f"check_config: rc={proc.returncode} total_errors={errors} total_warnings={warnings} log_errors={len(failures)}")
    if proc.returncode or errors or warnings or failures:
        if report.get("errors") or report.get("warnings"):
            print(json.dumps({"errors": report.get("errors"), "warnings": report.get("warnings")}, indent=2))
        return 1

    print("components:", ", ".join(sorted(report.get("components", []))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
