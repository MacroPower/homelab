"""Plan the settings collections: devices, entities, and integrations.

HA creates these objects itself, so the state never creates or deletes one.
It manages only the fields that each declared object sets. An unset field
stays as HA has it, and None clears it.
"""

from __future__ import annotations

from typing import Any

from hastate.model import Change, Live, category_key, normalize

DEVICES = "devices"
ENTITIES = "entities"
INTEGRATIONS = "integrations"
SETTINGS = (INTEGRATIONS, DEVICES, ENTITIES)
"""The settings collections in apply order. Entities follow devices, because disabling a device disables its entities."""

USER = "user"


def flag(field: str, live_by: str | None, want: bool, address: str, warnings: list[str]) -> tuple[str | None, str | None] | None:
    """Return the (old, new) change of a user flag such as disabled_by, or None when it already matches.

    HA records who set a flag. The state sets and clears only the `user`
    flag, so it never clears a flag that an integration, a device, or a
    config entry set. Asking to clear such a flag adds a warning instead.
    """
    if want and live_by is None:
        return (None, USER)
    if not want and live_by == USER:
        return (USER, None)
    if not want and live_by is not None:
        warnings.append(f"{address}: {field} is {live_by!r}, which the state cannot clear; only a {field} of 'user' can change")
    return None


def match_device(match: dict[str, Any], devices: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if "id" in match:
        return [d for d in devices if d["id"] == match["id"]]
    if "identifier" in match:
        want = [str(x) for x in match["identifier"]]
        return [d for d in devices if any([str(x) for x in i] == want for i in d.get("identifiers") or [])]
    kind, value = (str(x) for x in match["connection"])
    return [d for d in devices if any(c[0] == kind and str(c[1]).lower() == value.lower() for c in d.get("connections") or [])]


def plan_devices(
    want: dict[str, dict[str, Any]], live: Live, areas: set[str], labels: set[str]
) -> tuple[list[Change], list[str], list[str]]:
    devices = live.devices or []
    changes: list[Change] = []
    problems: list[str] = []
    warnings: list[str] = []
    owner: dict[str, str] = {}
    for key, spec in want.items():
        address = f"{DEVICES}.{key}"
        found = match_device(spec["match"], devices)
        if len(found) != 1:
            problems.append(f"{address}: the match {spec['match']} finds {len(found)} devices, not exactly one")
            continue
        dev = found[0]
        if dev["id"] in owner:
            problems.append(f"{address}: matches the same device as devices.{owner[dev['id']]}")
            continue
        owner[dev["id"]] = key
        diff: dict[str, tuple[Any, Any]] = {}
        for f in ("name_by_user", "area_id"):
            if f in spec and normalize(dev.get(f), False) != normalize(spec[f], False):
                diff[f] = (dev.get(f), spec[f])
        if "labels" in spec and normalize(dev.get("labels"), True) != normalize(spec["labels"], True):
            diff["labels"] = (normalize(dev.get("labels"), True), normalize(spec["labels"], True))
        if "disabled" in spec and (change := flag("disabled_by", dev.get("disabled_by"), spec["disabled"], address, warnings)):
            diff["disabled_by"] = change
        if spec.get("area_id") and spec["area_id"] not in areas:
            problems.append(f"{address}: area {spec['area_id']!r} does not exist and the state does not declare it")
        missing = sorted(set(spec.get("labels") or []) - labels)
        if missing:
            problems.append(f"{address}: labels {missing} do not exist and the state does not declare them; HA would drop them")
        if diff:
            name = spec.get("name_by_user") or dev.get("name_by_user") or dev.get("name") or dev["id"]
            changes.append(Change("update", DEVICES, key, name, diff, target=dev["id"]))
    return changes, problems, warnings


def final_disabled(live: Live, changes: list[Change]) -> dict[str, bool]:
    """Return whether each device is disabled after the apply.

    The answer starts from the live flags. The plan's integration changes
    come next, because HA disables a device when every config entry it
    belongs to is disabled, and enables a device that a config entry
    disabled when that entry is enabled. The plan's device changes come
    last.
    """
    entries = {e["entry_id"]: e.get("disabled_by") is not None for e in live.config_entries or []}
    toggled: set[str] = set()
    for c in changes:
        if c.collection == INTEGRATIONS and "disabled_by" in c.diff:
            entries[c.target] = c.diff["disabled_by"][1] is not None
            toggled.add(c.target)
    disabled: dict[str, bool] = {}
    for d in live.devices or []:
        own = [e for e in d.get("config_entries") or [] if e in entries]
        off = d.get("disabled_by") is not None
        if toggled & set(own):
            if d.get("disabled_by") == "config_entry" and not all(entries[e] for e in own):
                off = False
            elif d.get("disabled_by") is None and own and all(entries[e] for e in own):
                off = True
        disabled[d["id"]] = off
    for c in changes:
        if c.collection == DEVICES and "disabled_by" in c.diff:
            disabled[c.target] = c.diff["disabled_by"][1] is not None
    return disabled


def place_aliases(raw: list[str | None], want: list[str]) -> list[str | None]:
    """Return WANT with HA's placeholder for the entity's own name where RAW holds it.

    HA keeps a null placeholder for the entity's own name, and a new entity
    starts with [null]. Google Assistant and Alexa use the first alias as
    the primary name, so the placeholder keeps the place it had among the
    other aliases.
    """
    if None not in raw:
        return list(want)
    at = min(sum(1 for a in raw[: raw.index(None)] if a is not None), len(want))
    return [*want[:at], None, *want[at:]]


def plan_entities(
    want: dict[str, dict[str, Any]],
    live: Live,
    areas: set[str],
    labels: set[str],
    categories: dict[str, set[str]],
    changes: list[Change],
) -> tuple[list[Change], list[str], list[str]]:
    entities = live.entities or []
    by_id = {e["entity_id"]: e for e in entities}
    # HA scopes a unique id to the entity's domain and platform, so a sensor
    # and a binary_sensor of one platform can share one. A rename keeps the
    # domain, so the state key gives the domain to match on.
    by_unique = {(e["entity_id"].split(".")[0], e["platform"], e["unique_id"]): e for e in entities}
    disabled_devices = final_disabled(live, changes)
    details = live.entity_details or {}
    devices = {d["id"]: d for d in live.devices or []}
    names = {scope: {c["category_id"]: c["name"] for c in cats} for scope, cats in live.categories.items()}
    changes: list[Change] = []
    problems: list[str] = []
    warnings: list[str] = []
    owner: dict[str, str] = {}
    for key, spec in want.items():
        address = f"{ENTITIES}.{key}"
        diff: dict[str, tuple[Any, Any]] = {}
        if "match" in spec:
            m = spec["match"]
            domain = key.split(".")[0]
            ent = by_unique.get((domain, m["platform"], m["unique_id"]))
            if ent is None:
                problems.append(f"{address}: no {domain} entity of platform {m['platform']!r} has the unique id {m['unique_id']!r}")
                continue
            if ent["entity_id"] != key:
                if key in by_id:
                    problems.append(f"{address}: cannot rename {ent['entity_id']!r} to {key!r}, because another entity holds that id")
                    continue
                diff["entity_id"] = (ent["entity_id"], key)
        else:
            ent = by_id.get(key)
            if ent is None:
                problems.append(f"{address}: the entity registry has no {key!r}; HA cannot change entities without a unique id")
                continue
        identity = ent.get("id") or ent["entity_id"]
        if identity in owner:
            problems.append(f"{address}: is the same entity as entities.{owner[identity]}")
            continue
        owner[identity] = key
        extended = details.get(ent["entity_id"], {})
        for f in ("name", "icon", "area_id"):
            if f in spec and normalize(ent.get(f), False) != normalize(spec[f], False):
                diff[f] = (ent.get(f), spec[f])
        if "device_class" in spec and normalize(extended.get("device_class"), False) != normalize(spec["device_class"], False):
            diff["device_class"] = (extended.get("device_class"), spec["device_class"])
        if "labels" in spec and normalize(ent.get("labels"), True) != normalize(spec["labels"], True):
            diff["labels"] = (normalize(ent.get("labels"), True), normalize(spec["labels"], True))
        sent: dict[str, Any] = {}
        if "aliases" in spec:
            # The state lists only the aliases apart from HA's placeholder.
            # HA strips each alias and drops empty ones, so the plan does too.
            raw = list(extended.get("aliases") or [])
            have = [a for a in raw if a is not None]
            wanted = [a.strip() for a in spec["aliases"] or [] if a and a.strip()]
            if have != wanted:
                diff["aliases"] = (have, wanted)
                sent["aliases"] = place_aliases(raw, wanted)
        if "categories" in spec:
            have_names = {s: names.get(s, {}).get(cid, cid) for s, cid in (ent.get("categories") or {}).items()}
            want_names = {s: n for s, n in (spec["categories"] or {}).items() if n is not None}
            if {s: category_key(n) for s, n in have_names.items()} != {s: category_key(n) for s, n in want_names.items()}:
                diff["categories"] = (have_names, want_names)
            for scope, name in want_names.items():
                if category_key(name) not in categories.get(scope, set()):
                    problems.append(f"{address}: category {name!r} does not exist in the {scope!r} scope and the state does not declare it")
        if "hidden" in spec and (change := flag("hidden_by", ent.get("hidden_by"), spec["hidden"], address, warnings)):
            diff["hidden_by"] = change
        if "disabled" in spec:
            # HA rejects enabling an entity while its device is disabled. It
            # disables the entities of a device it disables, with the flag
            # `device`, and enables them again when it enables the device.
            device_id = ent.get("device_id") or ""
            device_was = (devices.get(device_id) or {}).get("disabled_by") is not None
            device_off = disabled_devices.get(device_id, False)
            live_by = ent.get("disabled_by")
            ends_by = live_by
            if live_by == "device" and device_was and not device_off:
                ends_by = None
            elif live_by is None and device_off and not device_was:
                ends_by = "device"
            if not spec["disabled"] and device_off:
                if ends_by is not None:
                    problems.append(f"{address}: its device stays disabled, so HA cannot enable the entity; enable the device too")
            elif ends_by == "device":
                # The device is enabled, so the flag is stale, and HA lets the state set it.
                diff["disabled_by"] = (live_by, USER if spec["disabled"] else None)
            elif change := flag("disabled_by", ends_by, spec["disabled"], address, warnings):
                diff["disabled_by"] = (live_by, change[1])
        if spec.get("area_id") and spec["area_id"] not in areas:
            problems.append(f"{address}: area {spec['area_id']!r} does not exist and the state does not declare it")
        missing = sorted(set(spec.get("labels") or []) - labels)
        if missing:
            problems.append(f"{address}: labels {missing} do not exist and the state does not declare them; HA would drop them")
        # HA rejects an area of the entity's own when the entity sits on a
        # device and has no name apart from the device's name. It checks only
        # an update that changes the area or the name.
        final_area = spec.get("area_id", ent.get("area_id"))
        final_name = spec.get("name", ent.get("name"))
        touched = "area_id" in diff or "name" in diff
        if touched and final_area and ent.get("device_id") and not final_name and not ent.get("original_name"):
            device = devices.get(ent["device_id"], {})
            problems.append(
                f"{address}: an entity without a name of its own cannot have an area of its own; "
                f"set its name, or set the area on its device {device.get('name_by_user') or device.get('name') or ent['device_id']!r}"
            )
        if diff:
            name = spec.get("name") or ent.get("name") or ent.get("original_name") or key
            change = Change("update", ENTITIES, key, name, diff, target=ent["entity_id"])
            change.sent = sent
            changes.append(change)
    return changes, problems, warnings


def visible_entries(live: Live) -> list[dict[str, Any]]:
    """Return the config entries the state can match. HA keeps ignored discoveries as entries with the source `ignore`."""
    return [e for e in live.config_entries or [] if e.get("source") != "ignore"]


def plan_integrations(want: dict[str, dict[str, Any]], live: Live) -> tuple[list[Change], list[str], list[str]]:
    entries = visible_entries(live)
    by_id = {e["entry_id"]: e for e in entries}
    changes: list[Change] = []
    problems: list[str] = []
    warnings: list[str] = []
    owner: dict[str, str] = {}
    for key, spec in want.items():
        address = f"{INTEGRATIONS}.{key}"
        if "entry_id" in spec:
            entry = by_id.get(spec["entry_id"])
            if entry is not None and entry["domain"] != spec["domain"]:
                problems.append(f"{address}: the entry {spec['entry_id']!r} belongs to {entry['domain']!r}, not {spec['domain']!r}")
                continue
            found = [entry] if entry else []
        else:
            found = [e for e in entries if e["domain"] == spec["domain"] and e["title"] == spec["title"]]
        if len(found) > 1:
            problems.append(f"{address}: {len(found)} {spec['domain']!r} entries have the title {spec['title']!r}; set entryId")
            continue
        if not found:
            changes.append(Change("missing", INTEGRATIONS, key, spec.get("title") or spec["domain"]))
            warnings.append(f"{address}: HA has no {spec['domain']!r} entry {spec.get('title') or spec.get('entry_id')!r}; add the integration in the UI")
            continue
        entry = found[0]
        if entry["entry_id"] in owner:
            problems.append(f"{address}: matches the same entry as integrations.{owner[entry['entry_id']]}")
            continue
        owner[entry["entry_id"]] = key
        diff: dict[str, tuple[Any, Any]] = {}
        for f in ("title", "pref_disable_new_entities", "pref_disable_polling"):
            if f in spec and spec[f] is None:
                problems.append(f"{address}: {f} is None, which HA rejects; leave the field unset to keep HA's value")
            elif f in spec and entry.get(f) != spec[f]:
                diff[f] = (entry.get(f), spec[f])
        if "disabled" in spec and (change := flag("disabled_by", entry.get("disabled_by"), spec["disabled"], address, warnings)):
            diff["disabled_by"] = change
        if diff:
            changes.append(Change("update", INTEGRATIONS, key, spec.get("title") or entry["title"], diff, target=entry["entry_id"]))
    for entry in entries:
        if entry["entry_id"] not in owner:
            changes.append(Change("unmanaged", INTEGRATIONS, entry["entry_id"], f"{entry['domain']}: {entry['title']}"))
    return changes, problems, warnings
