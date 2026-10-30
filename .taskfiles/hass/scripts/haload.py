#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["annotatedyaml"]
# ///
"""Load a staged Home Assistant config directory with Home Assistant's YAML loader.

Usage: haload.py STAGE

Loads STAGE/configuration.yaml with annotatedyaml, the loader Home Assistant
itself uses, so every !include, !include_dir_named, and !secret resolves as it
does on the Pi. The script then checks that every package name is a slug and
that every package is a mapping. It runs without Docker in about a second, so
it catches YAML and tag errors before the slower check_config run.

STAGE must come from stage.py, which adds the UI stubs and secrets.yaml that
configuration.yaml references.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from annotatedyaml import YAMLException, loader

SLUG = re.compile(r"^[a-z0-9]+(_[a-z0-9]+)*$")
"""Home Assistant's package name rule, the same pattern haconfig checks."""


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: haload.py STAGE", file=sys.stderr)
        return 2
    stage = Path(argv[1])

    problems: list[str] = []
    for name in ("secrets.yaml", "automations.yaml", "scripts.yaml", "scenes.yaml"):
        if not (stage / name).is_file():
            problems.append(f"{name} is missing; run stage.py before loading")
    if problems:
        for problem in problems:
            print(f"haload: {problem}", file=sys.stderr)
        return 1

    try:
        conf = loader.load_yaml(str(stage / "configuration.yaml"), loader.Secrets(stage))
    except (OSError, YAMLException) as err:
        print(f"haload: {err}", file=sys.stderr)
        return 1

    if not isinstance(conf, dict):
        print("haload: configuration.yaml did not load as a mapping", file=sys.stderr)
        return 1
    core = conf.get("homeassistant") or {}
    packages = core.get("packages") or {}
    if not isinstance(packages, dict):
        print("haload: homeassistant.packages did not resolve to a mapping", file=sys.stderr)
        return 1

    for name, body in packages.items():
        if not SLUG.match(str(name)):
            problems.append(f"package name {name!r} is not a slug")
        if not isinstance(body, dict):
            problems.append(f"package {name!r} is not a mapping")
    if problems:
        for problem in problems:
            print(f"haload: {problem}", file=sys.stderr)
        return 1

    print(f"loaded configuration.yaml with {len(packages)} package(s): {', '.join(packages) or 'none'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
