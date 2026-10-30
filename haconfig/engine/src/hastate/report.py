"""Format a Plan for a terminal."""

from __future__ import annotations

import json
import os
import sys
from typing import Any, TextIO

from hastate.plan import Plan

SYMBOLS = {"create": "+", "update": "~", "delete": "-", "unmanaged": "?"}
COLORS = {"create": "32", "update": "33", "delete": "31", "unmanaged": "2", "problem": "31"}


def use_color(stream: TextIO) -> bool:
    return stream.isatty() and "NO_COLOR" not in os.environ


def value(v: Any) -> str:
    return json.dumps(v, ensure_ascii=False)


def render(plan: Plan, url: str, color: bool = False) -> str:
    """Return the plan as text, one block per change, then the problems and a summary."""

    def paint(kind: str, text: str) -> str:
        return f"\x1b[{COLORS[kind]}m{text}\x1b[0m" if color else text

    lines = [f"Home Assistant {plan.ha_version} at {url}"]
    if plan.changes:
        lines.append("")
    for change in plan.changes:
        head = f"  {SYMBOLS[change.action]} {change.address}  {value(change.name)}"
        if change.action == "unmanaged":
            head += f"  (not in the state; prune {change.collection} to delete it)"
        lines.append(paint(change.action, head))
        for f, (old, new) in change.diff.items():
            lines.append(f"        {f}: {value(new)}" if change.action == "create" else f"        {f}: {value(old)} => {value(new)}")
        lines += [paint(change.action, f"        {note}") for note in change.notes]
    if plan.problems:
        lines += ["", paint("problem", "Problems that block an apply:")]
        lines += [paint("problem", f"  ! {p}") for p in plan.problems]
    lines += ["", summary(plan)]
    return "\n".join(lines)


def summary(plan: Plan) -> str:
    if not plan.actions:
        text = "No changes."
    else:
        text = f"Plan: {plan.count('create')} to create, {plan.count('update')} to update, {plan.count('delete')} to delete."
    if plan.count("unmanaged"):
        text += f" {plan.count('unmanaged')} unmanaged."
    return text


def print_plan(plan: Plan, url: str, stream: TextIO = sys.stdout) -> None:
    print(render(plan, url, use_color(stream)), file=stream)
