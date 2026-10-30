"""Compare the desired state with a live snapshot and list the changes.

The planner reads a desired state document and a Live snapshot, returns a
Plan, and has no side effects. hastate.live builds the snapshot, and
hastate.apply executes the plan.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any

STATE_FORMAT = 1
"""The state document version that this engine reads."""


@dataclass(frozen=True)
class Registry:
    """Registry describes one id-keyed HA registry and the fields the state owns."""

    collection: str
    prefix: str
    id_field: str
    fields: tuple[str, ...]
    set_fields: frozenset[str] = frozenset()

    @property
    def noun(self) -> str:
        return self.collection.removesuffix("s")


LABELS = Registry("labels", "config/label_registry", "label_id", ("name", "color", "icon", "description"))
FLOORS = Registry("floors", "config/floor_registry", "floor_id", ("name", "level", "icon", "aliases"), frozenset({"aliases"}))
AREAS = Registry(
    "areas",
    "config/area_registry",
    "area_id",
    ("name", "floor_id", "icon", "aliases", "labels", "picture", "temperature_entity_id", "humidity_entity_id"),
    frozenset({"aliases", "labels"}),
)

REGISTRIES = (LABELS, FLOORS, AREAS)
"""The id-keyed registries in apply order. Each one references only the registries before it."""

CATEGORIES = "categories"
CATEGORY_PREFIX = "config/category_registry"
CATEGORY_FIELDS = ("name", "icon")
CATEGORY_SCOPES = ("automation", "script", "scene", "helpers")
"""The category scopes that HA's frontend uses. A managed categories collection always covers them."""

AREA_SENSORS = {"temperature_entity_id": "temperature", "humidity_entity_id": "humidity"}
"""The area fields that name a sensor, mapped to the device class HA requires."""

CREATE_SUFFIX = " ~"
"""The suffix of a create's temporary name. HA's slugify drops it, so the object gets its key as its id."""

RENAME_SUFFIX = " ~haconfig~"
"""The suffix of the temporary name that frees an object's old name during an apply."""


def create_name(key: str) -> str:
    """Return the temporary name that a create of KEY uses, which HA slugifies to KEY."""
    return key + CREATE_SUFFIX


def rename_name(key: str) -> str:
    """Return the temporary name that moves object KEY out of the way of another object's new name."""
    return key + RENAME_SUFFIX


class StateError(Exception):
    """StateError means that the planner cannot read the state document."""


@dataclass
class Live:
    """Live is a snapshot of the registries that a plan reads.

    `registries` maps a collection name to HA's list result, and `categories`
    maps a scope to its list. `states` maps an entity id to its state object,
    and is None when no area names a sensor. `entities` and `devices` hold
    the entity and device registries, and are None when the state prunes
    neither labels nor categories.
    """

    ha_version: str
    registries: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    categories: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    states: dict[str, dict[str, Any]] | None = None
    entities: list[dict[str, Any]] | None = None
    devices: list[dict[str, Any]] | None = None


@dataclass
class Change:
    """Change is one planned operation on one registry object.

    `action` is create, update, delete, or unmanaged. `diff` maps each field
    to its live and desired value, with None as the live value of a create.
    `target` is the live id of an update or a delete, and the desired fields of
    a create. `notes` lists the side effects of a delete outside the state,
    such as the entities that lose a label.
    """

    action: str
    collection: str
    key: str
    name: str
    diff: dict[str, tuple[Any, Any]] = field(default_factory=dict)
    target: Any = None
    scope: str | None = None
    notes: list[str] = field(default_factory=list)

    @property
    def address(self) -> str:
        if self.scope is not None:
            return f"{self.collection}.{self.scope}.{self.key}"
        return f"{self.collection}.{self.key}"


@dataclass
class Plan:
    """Plan lists the changes and the problems that block an apply."""

    ha_version: str
    changes: list[Change] = field(default_factory=list)
    problems: list[str] = field(default_factory=list)

    @property
    def actions(self) -> list[Change]:
        return [c for c in self.changes if c.action != "unmanaged"]

    def count(self, action: str) -> int:
        return sum(1 for c in self.changes if c.action == action)

    def fingerprint(self) -> str:
        """Return a string that two plans share exactly when they hold the same actions."""
        return json.dumps([[c.action, c.address, c.diff, c.target] for c in self.actions], sort_keys=True, default=str)


def name_key(name: str) -> str:
    """Return the key that HA's registries compare names by: casefolded, without whitespace."""
    return re.sub(r"\s+", "", name.casefold())


def normalize(value: Any, as_set: bool) -> Any:
    """Return VALUE in the form HA stores it, so two equal values compare equal.

    A set field becomes a sorted list without duplicates or blank strings. HA
    stores area and floor aliases and labels as sets, so their order carries
    no meaning.
    """
    if as_set:
        return sorted({v.strip() for v in value or [] if isinstance(v, str) and v.strip()})
    if value == "":
        return None
    return value


def category_key(name: str) -> str:
    """Return the key that HA's category registry compares names by: casefolded only."""
    return name.casefold()


def is_empty(value: Any) -> bool:
    return value is None or value == [] or value == ""


def check_format(desired: dict[str, Any]) -> None:
    if desired.get("format") != STATE_FORMAT:
        raise StateError(f"state format {desired.get('format')!r} is not {STATE_FORMAT}; render the state with this haconfig version")


def plan(desired: dict[str, Any], live: Live) -> Plan:
    """Return the changes that turn LIVE into DESIRED, and every problem that blocks them."""
    check_format(desired)
    prune = set(desired.get("prune", []))
    result = Plan(live.ha_version)
    final_ids: dict[str, set[str]] = {}

    for reg in REGISTRIES:
        current = live.registries.get(reg.collection, [])
        if reg.collection not in desired:
            final_ids[reg.collection] = {o[reg.id_field] for o in current}
            continue
        want = desired[reg.collection]
        changes, problems, kept = _plan_registry(reg, want, current, reg.collection in prune)
        result.changes += changes
        result.problems += problems
        final_ids[reg.collection] = set(want) | kept

    if CATEGORIES in desired:
        changes, problems = _plan_categories(desired[CATEGORIES], live.categories, CATEGORIES in prune)
        result.changes += changes
        result.problems += problems

    result.problems += _check_areas(desired.get("areas", {}), final_ids, live.states)
    result.problems += _check_cascades(result.changes, desired, live)
    return result


def _plan_registry(
    reg: Registry, want: dict[str, dict[str, Any]], current: list[dict[str, Any]], prune: bool
) -> tuple[list[Change], list[str], set[str]]:
    by_id = {o[reg.id_field]: o for o in current}
    changes: list[Change] = []
    problems: list[str] = []

    for key, fields in want.items():
        have = by_id.get(key)
        if have is None:
            diff = {f: (None, normalize(fields.get(f), f in reg.set_fields)) for f in reg.fields if not is_empty(fields.get(f))}
            changes.append(Change("create", reg.collection, key, fields["name"], diff, target=fields))
            continue
        diff = {}
        for f in reg.fields:
            old, new = normalize(have.get(f), f in reg.set_fields), normalize(fields.get(f), f in reg.set_fields)
            if old != new:
                diff[f] = (old, new)
        if diff:
            changes.append(Change("update", reg.collection, key, fields["name"], diff, target=key))

    kept: set[str] = set()
    for obj_id, have in by_id.items():
        if obj_id in want:
            continue
        if prune:
            changes.append(Change("delete", reg.collection, obj_id, have.get("name") or obj_id, target=obj_id))
        else:
            kept.add(obj_id)
            changes.append(Change("unmanaged", reg.collection, obj_id, have.get("name") or obj_id))

    # HA rejects a name whose key another object holds. The final names are
    # the desired names plus the names of the live objects the apply keeps.
    owners: dict[str, list[str]] = {}
    for key, fields in want.items():
        owners.setdefault(name_key(fields["name"]), []).append(key)
    for obj_id in kept:
        owners.setdefault(name_key(by_id[obj_id].get("name") or ""), []).append(obj_id)
    for keys in owners.values():
        if len(keys) > 1:
            problems.append(f"{reg.collection}: {', '.join(sorted(keys))} would share one name, ignoring case and whitespace")

    # The apply creates an object under a temporary name that HA slugifies to
    # KEY, so HA assigns KEY as its id, then renames it. That name must be free.
    live_names = {name_key(o.get("name") or ""): o[reg.id_field] for o in current}
    for change in changes:
        if change.action == "create" and name_key(create_name(change.key)) in live_names:
            holder = live_names[name_key(create_name(change.key))]
            problems.append(
                f"{reg.collection}.{change.key}: the live {reg.noun} {holder!r} holds the name {create_name(change.key)!r}, "
                f"which the create needs for one step; rename that {reg.noun} first"
            )
    return changes, problems, kept


def _plan_categories(
    want: dict[str, dict[str, dict[str, Any]]], current: dict[str, list[dict[str, Any]]], prune: bool
) -> tuple[list[Change], list[str]]:
    changes: list[Change] = []
    problems: list[str] = []
    # The live scopes that the state does not name still belong to the
    # managed collection, so their categories show as unmanaged or deleted.
    for scope in list(want) + [s for s in current if s not in want]:
        entries = want.get(scope, {})
        by_name = {category_key(c["name"]): c for c in current.get(scope, [])}
        matched: set[str] = set()
        for key, fields in entries.items():
            have = by_name.get(category_key(fields["name"]))
            if have is None:
                diff = {f: (None, fields.get(f)) for f in CATEGORY_FIELDS if not is_empty(fields.get(f))}
                changes.append(Change("create", CATEGORIES, key, fields["name"], diff, target=fields, scope=scope))
                continue
            matched.add(have["category_id"])
            diff = {f: (have.get(f), fields.get(f)) for f in CATEGORY_FIELDS if normalize(have.get(f), False) != normalize(fields.get(f), False)}
            if diff:
                changes.append(Change("update", CATEGORIES, key, fields["name"], diff, target=have["category_id"], scope=scope))
        for have in current.get(scope, []):
            if have["category_id"] in matched:
                continue
            action = "delete" if prune else "unmanaged"
            changes.append(Change(action, CATEGORIES, have["category_id"], have["name"], target=have["category_id"], scope=scope))
    return changes, problems


def _check_areas(
    areas: dict[str, dict[str, Any]], final_ids: dict[str, set[str]], states: dict[str, dict[str, Any]] | None
) -> list[str]:
    problems = []
    for key, fields in areas.items():
        floor = fields.get("floor_id")
        if floor and floor not in final_ids["floors"]:
            problems.append(f"areas.{key}: floor {floor!r} does not exist and the state does not declare it")
        missing = sorted(set(fields.get("labels") or []) - final_ids["labels"])
        if missing:
            problems.append(f"areas.{key}: labels {missing} do not exist and the state does not declare them; HA would drop them")
        for attr, device_class in AREA_SENSORS.items():
            entity_id = fields.get(attr)
            if not entity_id:
                continue
            state = (states or {}).get(entity_id)
            if state is None:
                problems.append(f"areas.{key}: {attr} {entity_id!r} has no state in HA")
            elif state.get("attributes", {}).get("device_class") != device_class:
                problems.append(f"areas.{key}: {attr} {entity_id!r} must have the {device_class!r} device class")
    return problems


def _check_cascades(changes: list[Change], desired: dict[str, Any], live: Live) -> list[str]:
    """Block deletes that change areas the state does not declare, and note their other side effects.

    HA clears a deleted floor from every area on it, and removes a deleted
    label from every area, device, and entity that carries it. It also
    removes a deleted category from every entity in that category. The state
    owns only the areas it declares, so a delete that would change another
    area is a problem. The plan notes the devices and entities that a delete
    changes.
    """
    deletes = {(c.collection, c.key): c for c in changes if c.action == "delete"}
    if not deletes:
        return []
    declared = set(desired.get("areas", {}))
    deleted_areas = {k for (coll, k) in deletes if coll == "areas"}
    problems = []
    for a in live.registries.get("areas", []):
        if a["area_id"] in declared or a["area_id"] in deleted_areas:
            continue
        if ("floors", a.get("floor_id")) in deletes:
            problems.append(
                f"floors.{a['floor_id']}: deleting it clears the floor of the area {a['area_id']!r}, which the state does not declare; "
                "declare that area or move it to another floor first"
            )
        for label in a.get("labels") or []:
            if ("labels", label) in deletes:
                problems.append(
                    f"labels.{label}: deleting it removes it from the area {a['area_id']!r}, which the state does not declare; "
                    "declare that area or remove the label from it first"
                )
    for (coll, key), change in deletes.items():
        if coll == "labels":
            entities = sum(1 for e in live.entities or [] if key in (e.get("labels") or []))
            devices = sum(1 for d in live.devices or [] if key in (d.get("labels") or []))
            if entities or devices:
                change.notes.append(f"also removes the label from {entities} entities and {devices} devices")
        elif coll == CATEGORIES:
            entities = sum(1 for e in live.entities or [] if (e.get("categories") or {}).get(change.scope) == key)
            if entities:
                change.notes.append(f"also removes the category from {entities} entities")
    return problems


def needs_states(desired: dict[str, Any]) -> bool:
    """Report whether any area names a sensor, so the snapshot must hold states."""
    return any(fields.get(attr) for fields in desired.get("areas", {}).values() for attr in AREA_SENSORS)
