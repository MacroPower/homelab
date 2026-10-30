"""Execute a Plan against a live instance."""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

from hastate import apps, hacs, settings
from hastate.client import Client
from hastate.model import (
    category_key,
)
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
    category_names: bool = False
    """category_names marks an entity update whose `categories` map holds names, which the apply resolves to ids."""
    run: Callable[[Client], Awaitable[Any]] | None = None
    """run replaces `command` for a step whose fields depend on live state at the time it runs, such as merged app options."""


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

    Categories follow the registries. The settings collections run last, in
    SETTINGS order, because they reference the objects before them.
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

    for c in (c for c in actions if c.collection == settings.INTEGRATIONS):
        prefs = {f: new for f, (_, new) in c.diff.items() if f != "disabled_by"}
        if prefs:
            out.append(Step(f"update {c.address}", "config_entries/update", {"entry_id": c.target, **prefs}))
        if "disabled_by" in c.diff:
            new = c.diff["disabled_by"][1]
            out.append(Step(f"{'disable' if new else 'enable'} {c.address}", "config_entries/disable", {"entry_id": c.target, "disabled_by": new}))
    for c in (c for c in actions if c.collection == settings.DEVICES):
        out.append(Step(f"update {c.address}", "config/device_registry/update", {"device_id": c.target, **{f: new for f, (_, new) in c.diff.items()}}))
    for c in (c for c in actions if c.collection == settings.ENTITIES):
        fields: dict[str, Any] = {"entity_id": c.target}
        for f, (old, new) in c.diff.items():
            if f == "entity_id":
                fields["new_entity_id"] = new
            elif f == "categories":
                # A set map is the whole map, so each scope the entity leaves gets null.
                fields["categories"] = {**{scope: None for scope in old if scope not in new}, **new}
            else:
                fields[f] = c.sent.get(f, new)
        out.append(Step(f"update {c.address}", "config/entity_registry/update", fields, category_names="categories" in fields))

    out += _app_steps(actions)
    out += _hacs_steps(actions)
    return out


def _app_steps(actions: list[Any]) -> list[Step]:
    """Return the steps for app repositories and apps.

    Repository adds run first, so an app from a new repository is in the
    store when its install runs. Uninstalls run next, so an app that
    replaces another can take its host ports, and then the repository
    removes, which need those uninstalls. Each declared app then installs or
    updates, and gets its options, settings, and ports.

    The apps start and stop last, so a host port that one app releases is
    free before another takes it. The stops run first, then the restarts of
    running apps whose options or ports changed, then the starts.
    """
    out: list[Step] = []
    repositories = [c for c in actions if c.collection == apps.REPOSITORIES]
    declared = [c for c in actions if c.collection == apps.APPS and c.action in ("create", "update")]
    changed: dict[str, bool] = {}
    for c in (c for c in repositories if c.action == "create"):
        out.append(Step(f"add {c.address}", "supervisor/api", run=lambda cl, url=c.target: apps.add_repository(cl, url)))
    for c in (c for c in actions if c.collection == apps.APPS and c.action == "delete"):
        out.append(Step(f"uninstall {c.address}", "supervisor/api", run=lambda cl, s=c.key: apps.uninstall(cl, s)))
    for c in (c for c in repositories if c.action == "delete"):
        out.append(Step(f"remove {c.address}", "supervisor/api", run=lambda cl, slug=c.target: cl.supervisor("delete", f"/store/repositories/{slug}")))
    for c in declared:
        slug, spec = c.key, c.target
        if c.action == "create":
            out.append(Step(f"install {c.address}", "supervisor/api", run=lambda cl, s=slug, pin=spec.get("version"): apps.install(cl, s, pin)))
        elif "version" in c.diff:
            out.append(Step(f"update {c.address} to {c.diff['version'][1]}", "supervisor/api", run=lambda cl, s=slug: apps.update(cl, s)))

        async def configure(cl: Client, s: str = slug, sp: dict[str, Any] = spec) -> None:
            changed[s] = await apps.configure(cl, s, sp)

        out.append(Step(f"configure {c.address}", "supervisor/api", run=configure))
    for c in (c for c in declared if c.target.get("started") is False and "state" in c.diff):
        out.append(Step(f"stop {c.address}", "supervisor/api", run=lambda cl, s=c.key: apps.set_state(cl, s, False, restart=False)))
    for c in declared:
        settings_changed = any(k.startswith(("options.", "network.")) for k in c.diff)
        if c.action == "update" and settings_changed and "state" not in c.diff and c.target.get("started") is not False:
            out.append(Step(f"restart {c.address}", "supervisor/api", run=lambda cl, s=c.key: apps.set_state(cl, s, None, restart=changed.get(s, False))))
    for c in (c for c in declared if c.target.get("started") is True and "state" in c.diff):
        out.append(Step(f"start {c.address}", "supervisor/api", run=lambda cl, s=c.key: apps.set_state(cl, s, True, restart=False)))
    return out


def _hacs_steps(actions: list[Any]) -> list[Step]:
    """Return the HACS steps, with HACS's own repository first, because its update can change the commands the others use."""
    mine = [c for c in actions if c.collection == hacs.HACS]
    mine.sort(key=lambda c: c.key.lower() != hacs.SELF)
    out: list[Step] = []
    for c in mine:
        if c.action in ("create", "update"):
            out.append(Step(f"download {c.address} {c.target['version']}", "hacs/repository/download", run=lambda cl, t=c.target: hacs.install(cl, t)))
        elif c.action == "delete":
            out.append(Step(f"remove {c.address}", "hacs/repository/remove", run=lambda cl, t=c.target: hacs.remove(cl, t)))
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
            if step.run is not None:
                result = await step.run(client)
            else:
                fields = await _resolve_categories(client, step.fields) if step.category_names else step.fields
                result = await client.call(step.command, **fields)
            if isinstance(result, dict) and result.get("require_restart"):
                log(f"  {step.description}: HA must restart to finish this change")
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


async def _resolve_categories(client: Client, fields: dict[str, Any]) -> dict[str, Any]:
    """Return FIELDS with each category name replaced by its id.

    The apply resolves names when it runs the step, because a category that
    the same apply creates has no id before then.
    """
    resolved: dict[str, Any] = {}
    for scope, name in fields["categories"].items():
        if name is None:
            resolved[scope] = None
            continue
        cats = await client.call(f"{CATEGORY_PREFIX}/list", scope=scope)
        ids = [c["category_id"] for c in cats if category_key(c["name"]) == category_key(name)]
        if len(ids) != 1:
            raise RuntimeError(f"found {len(ids)} categories named {name!r} in the {scope!r} scope")
        resolved[scope] = ids[0]
    return {**fields, "categories": resolved}
