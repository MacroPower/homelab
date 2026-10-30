"""Format a Plan for a terminal."""

from __future__ import annotations

import json
import os
import sys
from typing import Any, TextIO

from hastate.plan import Plan

SYMBOLS = {"create": "+", "update": "~", "delete": "-", "unmanaged": "?", "missing": "!"}
COLORS = {"create": "32", "update": "33", "delete": "31", "unmanaged": "2", "missing": "35", "problem": "31", "warning": "35"}


def use_color(stream: TextIO) -> bool:
    return stream.isatty() and "NO_COLOR" not in os.environ


def value(v: Any) -> str:
    return json.dumps(v, ensure_ascii=False)


def shown(v: Any) -> Any:
    """Return V in the form the report prints for a sensitive field: a `!secret` reference or null as itself, anything else hidden."""
    if v is None or (isinstance(v, str) and v.startswith("!secret ")):
        return v
    return "(sensitive)"


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
            if change.collection in ("integrations",):
                head += "  (not in the state)"
            else:
                head += f"  (not in the state; prune {change.collection} to delete it)"
        elif change.action == "missing":
            head += "  (declared, but HA does not have it)"
        lines.append(paint(change.action, head))
        for f, (old, new) in change.diff.items():
            if f in change.sensitive:
                old, new = shown(old), shown(new)
            lines.append(f"        {f}: {value(new)}" if change.action == "create" else f"        {f}: {value(old)} => {value(new)}")
        lines += [paint(change.action, f"        {note}") for note in change.notes]
    if plan.warnings:
        lines += ["", paint("warning", "Warnings:")]
        lines += [paint("warning", f"  ! {w}") for w in plan.warnings]
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
