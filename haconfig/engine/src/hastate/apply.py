"""Execute a Plan against a live instance."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any

from hastate.client import Client
from hastate.plan import (
    AREAS,
    CATEGORIES,
    CATEGORY_PREFIX,
    FLOORS,
    LABELS,
    REGISTRIES,
    Plan,
    create_name,
    is_empty,
    name_key,
    rename_name,
)

BY_COLLECTION = {reg.collection: reg for reg in REGISTRIES}

DELETE_ORDER = (AREAS.collection, FLOORS.collection, LABELS.collection, CATEGORIES)
"""Deletes run first, from the objects that reference others to the objects they reference."""


class ApplyError(Exception):
    """ApplyError means a step failed. `done` lists the steps that finished before it."""

    def __init__(self, message: str, done: list[str]) -> None:
        super().__init__(message)
        self.done = done


@dataclass
class Step:
    """Step is one write command. A create step carries the id it must produce in `expect`."""

    description: str
    command: str
    fields: dict[str, Any] = field(default_factory=dict)
    expect: tuple[str, str] | None = None
    prefix: str = ""


def steps(plan: Plan) -> list[Step]:
    """Return the write commands that execute PLAN, in order.

    Deletes run first, so a create or a rename can take a name that a pruned
    object held. Each registry then runs in REGISTRIES order, so an object
    exists before another references it. Within a registry:

    1. Each renamed object whose old name another object needs moves to a
       temporary name, so swaps and chains of renames never clash.
    2. Each create runs under a temporary name that HA slugifies to the key.
    3. Each created object gets its real name.
    4. Each update sets its changed fields, including the new name.
    """
    actions = plan.actions
    out: list[Step] = []
    for coll in DELETE_ORDER:
        for c in (c for c in actions if c.collection == coll and c.action == "delete"):
            if coll == CATEGORIES:
                out.append(Step(f"delete {c.address}", f"{CATEGORY_PREFIX}/delete", {"scope": c.scope, "category_id": c.target}))
            else:
                reg = BY_COLLECTION[coll]
                out.append(Step(f"delete {c.address}", f"{reg.prefix}/delete", {reg.id_field: c.target}))

    for reg in REGISTRIES:
        creates = [c for c in actions if c.collection == reg.collection and c.action == "create"]
        updates = [c for c in actions if c.collection == reg.collection and c.action == "update"]
        renames = [u for u in updates if "name" in u.diff]
        needed = {name_key(c.target["name"]) for c in creates} | {name_key(u.diff["name"][1]) for u in renames}
        update = f"{reg.prefix}/update"
        for u in renames:
            if name_key(u.diff["name"][0] or "") in needed:
                out.append(Step(f"free the name of {u.address}", update, {reg.id_field: u.key, "name": rename_name(u.key)}))
        for c in creates:
            # HA rejects null fields on create, so the create sends only fields with a value.
            extra = {f: v for f, v in c.target.items() if f != "name" and f in reg.fields and not is_empty(v)}
            out.append(
                Step(
                    f"create {c.address}",
                    f"{reg.prefix}/create",
                    {"name": create_name(c.key), **extra},
                    expect=(reg.id_field, c.key),
                    prefix=reg.prefix,
                )
            )
        for c in creates:
            out.append(Step(f"name {c.address}", update, {reg.id_field: c.key, "name": c.target["name"]}))
        for u in updates:
            out.append(Step(f"update {u.address}", update, {reg.id_field: u.key, **{f: new for f, (_, new) in u.diff.items()}}))

    for c in (c for c in actions if c.collection == CATEGORIES and c.action in ("create", "update")):
        if c.action == "create":
            extra = {f: v for f, v in c.target.items() if f != "name" and not is_empty(v)}
            out.append(Step(f"create {c.address}", f"{CATEGORY_PREFIX}/create", {"scope": c.scope, "name": c.target["name"], **extra}))
        else:
            fields = {f: new for f, (_, new) in c.diff.items()}
            out.append(Step(f"update {c.address}", f"{CATEGORY_PREFIX}/update", {"scope": c.scope, "category_id": c.target, **fields}))
    return out


async def apply(client: Client, plan: Plan, log: Callable[[str], None] = print) -> list[str]:
    """Run every step of PLAN and return the description of each finished step.

    The apply stops at the first failed step and raises ApplyError. Steps that
    finished stay applied, so a new plan shows what remains.
    """
    if plan.problems:
        raise ApplyError("the plan has problems; fix them before applying", [])
    done: list[str] = []
    for step in steps(plan):
        try:
            result = await client.call(step.command, **step.fields)
            if step.expect:
                id_field, key = step.expect
                got = result[id_field]
                if got != key:
                    # The object is new and nothing references it yet, so
                    # deleting it again leaves HA as it was.
                    await client.call(f"{step.prefix}/delete", **{id_field: got})
                    raise RuntimeError(f"HA assigned the id {got!r} instead of {key!r}, so the apply deleted it again")
        except Exception as err:
            raise ApplyError(f"{step.description} failed: {err}", done) from err
        done.append(step.description)
        log(f"  {step.description}: done")
    return done
