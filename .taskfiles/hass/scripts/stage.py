#!/usr/bin/env python3
"""Stage a rendered Home Assistant config directory for offline validation.

Usage: stage.py OUT STAGE

Copies the rendered directory OUT to STAGE, replacing any earlier stage. It
then writes empty stubs for the three UI-owned files that configuration.yaml
includes, and copies secrets.example.yaml to secrets.yaml so that every
!secret resolves to its declared fake value. haload.py and checkconfig.py both
read STAGE, and OUT stays exactly as the render wrote it.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

UI_STUBS = {
    "automations.yaml": "[]\n",
    "scripts.yaml": "{}\n",
    "scenes.yaml": "[]\n",
}
"""Stub content for each UI-owned file. A fresh install holds the same content."""


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: stage.py OUT STAGE", file=sys.stderr)
        return 2
    out, stage = Path(argv[1]), Path(argv[2])

    if not (out / "configuration.yaml").is_file():
        print(f"stage: {out} has no configuration.yaml; run hass:render first", file=sys.stderr)
        return 1

    shutil.rmtree(stage, ignore_errors=True)
    shutil.copytree(out, stage)
    for name, stub in UI_STUBS.items():
        (stage / name).write_text(stub)

    example = stage / "secrets.example.yaml"
    if example.is_file():
        shutil.copyfile(example, stage / "secrets.yaml")
    else:
        (stage / "secrets.yaml").write_text("{}\n")

    print(stage)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
