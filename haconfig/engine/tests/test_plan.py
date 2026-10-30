from __future__ import annotations

import pytest

from hastate.apply import steps
from hastate.plan import Live, StateError, plan
from hastate.report import render


def area(area_id: str, name: str, **fields: object) -> dict[str, object]:
    base = {
        "area_id": area_id,
        "name": name,
        "floor_id": None,
        "icon": None,
        "aliases": [],
        "labels": [],
        "picture": None,
        "temperature_entity_id": None,
        "humidity_entity_id": None,
        "created_at": 0.0,
        "modified_at": 0.0,
    }
    return base | fields


def want_area(name: str, **fields: object) -> dict[str, object]:
    base = {
        "name": name,
        "floor_id": None,
        "icon": None,
        "aliases": [],
        "labels": [],
        "picture": None,
        "temperature_entity_id": None,
        "humidity_entity_id": None,
    }
    return base | fields


def state(**collections: object) -> dict[str, object]:
    return {"format": 1, "prune": [], **collections}


def by_address(result):
    return {c.address: c for c in result.changes}


def test_matching_state_has_no_changes():
    live = Live("2026.10.4", {"areas": [area("kitchen", "Kitchen", aliases=["Cook", "Galley"])]})
    result = plan(state(areas={"kitchen": want_area("Kitchen", aliases=["Galley", "Cook", " "])}), live)
    assert result.changes == [] and result.problems == []
    assert "No changes." in render(result, "http://ha")


def test_update_lists_only_changed_fields():
    live = Live("x", {"areas": [area("kitchen", "Kitchen", icon="mdi:stove")]})
    result = plan(state(areas={"kitchen": want_area("Cook Space", icon="mdi:stove", labels=[])}), live)
    change = by_address(result)["areas.kitchen"]
    assert change.action == "update"
    assert change.diff == {"name": ("Kitchen", "Cook Space")}


def test_create_lists_set_fields_only():
    result = plan(state(areas={"office": want_area("Home Office", icon="mdi:desk")}), Live("x", {"areas": []}))
    change = by_address(result)["areas.office"]
    assert change.action == "create"
    assert change.diff == {"name": (None, "Home Office"), "icon": (None, "mdi:desk")}


def test_live_objects_outside_the_state_are_unmanaged_unless_pruned():
    live = Live("x", {"areas": [area("garage", "Garage")]})
    kept = plan(state(areas={}), live)
    pruned = plan(state(areas={}, prune=["areas"]), live)
    assert by_address(kept)["areas.garage"].action == "unmanaged" and kept.actions == []
    assert by_address(pruned)["areas.garage"].action == "delete"


def test_unset_collection_is_not_read_or_touched():
    live = Live("x", {"areas": [area("garage", "Garage")]})
    assert plan(state(), live).changes == []


def test_area_needs_existing_floor_and_labels():
    live = Live("x", {"areas": [], "floors": [{"floor_id": "ground", "name": "Ground"}], "labels": []})
    ok = plan(state(areas={"hall": want_area("Hall", floor_id="ground")}), live)
    bad = plan(state(areas={"hall": want_area("Hall", floor_id="attic", labels=["lights"])}), live)
    assert ok.problems == []
    assert any("floor 'attic' does not exist" in p for p in bad.problems)
    assert any("labels ['lights'] do not exist" in p for p in bad.problems)


def test_pruned_floor_cannot_stay_referenced():
    live = Live("x", {"areas": [area("hall", "Hall", floor_id="ground")], "floors": [{"floor_id": "ground", "name": "Ground"}]})
    result = plan(state(floors={}, areas={"hall": want_area("Hall", floor_id="ground")}, prune=["floors"]), live)
    assert any("floor 'ground' does not exist" in p for p in result.problems)


def test_name_clash_with_kept_object():
    live = Live("x", {"areas": [area("kitchen", "Kitchen")]})
    result = plan(state(areas={"cook": want_area("kitchen")}), live)
    assert any("cook, kitchen would share one name" in p for p in result.problems)


def test_create_needs_its_temporary_name_free():
    live = Live("x", {"areas": [area("study_2", "study ~")]})
    result = plan(state(areas={"study": want_area("Reading Room"), "study_2": want_area("study ~")}), live)
    assert any("areas.study: the live area 'study_2' holds the name 'study ~'" in p for p in result.problems)


def test_area_sensor_must_exist_with_device_class():
    live = Live("x", {"areas": []}, states={"sensor.t": {"attributes": {"device_class": "humidity"}}})
    result = plan(state(areas={"hall": want_area("Hall", temperature_entity_id="sensor.t", humidity_entity_id="sensor.h")}), live)
    assert any("'sensor.t' must have the 'temperature' device class" in p for p in result.problems)
    assert any("'sensor.h' has no state in HA" in p for p in result.problems)


def test_categories_match_by_name_within_scope():
    live = Live("x", categories={"automation": [{"category_id": "01ABC", "name": "lighting", "icon": None}, {"category_id": "01DEF", "name": "Old", "icon": None}]})
    desired = state(categories={"automation": {"lights": {"name": "Lighting", "icon": "mdi:lightbulb"}, "new": {"name": "New", "icon": None}}})
    result = by_address(plan(desired, live))
    assert result["categories.automation.lights"].action == "update"
    assert result["categories.automation.lights"].target == "01ABC"
    assert result["categories.automation.new"].action == "create"
    assert result["categories.automation.01DEF"].action == "unmanaged"


def test_apply_order_deletes_first_then_writes_references_first():
    live = Live("x", {"areas": [area("old", "Old")], "floors": [], "labels": []})
    desired = state(
        areas={"hall": want_area("Hall", floor_id="ground", labels=["lights"])},
        floors={"ground": {"name": "Ground", "level": 0, "icon": None, "aliases": []}},
        labels={"lights": {"name": "Lights", "color": None, "icon": None, "description": None}},
        prune=["areas"],
    )
    result = plan(desired, live)
    assert result.problems == []
    assert [s.description for s in steps(result)] == [
        "delete areas.old",
        "create labels.lights",
        "name labels.lights",
        "create floors.ground",
        "name floors.ground",
        "create areas.hall",
        "name areas.hall",
    ]


def test_wrong_format_is_rejected():
    with pytest.raises(StateError):
        plan({"format": 2}, Live("x"))
