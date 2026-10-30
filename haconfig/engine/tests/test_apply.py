from __future__ import annotations

import asyncio

import pytest
from fakeha import FakeHA

from hastate.apply import ApplyError, apply, steps
from hastate.live import read_live
from hastate.plan import plan


def area(name: str, **fields: object) -> dict[str, object]:
    return {"name": name, "floor_id": None, "icon": None, "aliases": [], "labels": [], "picture": None, "temperature_entity_id": None, "humidity_entity_id": None} | fields


def floor(name: str, **fields: object) -> dict[str, object]:
    return {"name": name, "level": None, "icon": None, "aliases": []} | fields


def label(name: str) -> dict[str, object]:
    return {"name": name, "color": None, "icon": None, "description": None}


def state(**collections: object) -> dict[str, object]:
    return {"format": 1, "prune": [], **collections}


async def converge(ha: FakeHA, desired: dict) -> tuple:
    """Plan, apply, and plan again. Return the first plan and the second."""
    before = plan(desired, await read_live(ha, desired))
    assert before.problems == [], before.problems
    await apply(ha, before, log=lambda _: None)
    after = plan(desired, await read_live(ha, desired))
    return before, after


def run(coro):
    return asyncio.run(coro)


def test_new_id_for_existing_name_after_prune():
    ha = FakeHA(areas=[{"area_id": "living_room", "name": "Living Room"}])
    _, after = run(converge(ha, state(areas={"lounge": area("Living Room")}, prune=["areas"])))
    assert after.actions == []
    assert list(ha.data["areas"]) == ["lounge"]


def test_new_object_takes_a_name_that_a_rename_frees():
    ha = FakeHA(areas=[{"area_id": "kitchen", "name": "Kitchen"}])
    _, after = run(converge(ha, state(areas={"kitchen": area("Old Kitchen"), "galley": area("Kitchen")})))
    assert after.actions == []
    assert ha.data["areas"]["galley"]["name"] == "Kitchen"


def test_name_swap_and_chain():
    ha = FakeHA(
        floors=[{"floor_id": "a", "name": "Alpha"}, {"floor_id": "b", "name": "Beta"}],
        areas=[{"area_id": "a_room", "name": "Den"}, {"area_id": "b_room", "name": "Bedroom"}, {"area_id": "c_room", "name": "Study"}],
    )
    desired = state(
        floors={"a": floor("Beta"), "b": floor("Alpha")},
        areas={"a_room": area("Bedroom"), "b_room": area("Study"), "c_room": area("Den")},
    )
    _, after = run(converge(ha, desired))
    assert after.actions == []
    assert {k: v["name"] for k, v in ha.data["floors"].items()} == {"a": "Beta", "b": "Alpha"}


def test_create_whose_key_is_another_creates_name():
    ha = FakeHA()
    _, after = run(converge(ha, state(areas={"den": area("Office"), "office": area("Den")})))
    assert after.actions == []
    assert {k: v["name"] for k, v in ha.data["areas"].items()} == {"den": "Office", "office": "Den"}


def test_steps_delete_first_and_free_names_before_creates():
    ha = FakeHA(areas=[{"area_id": "kitchen", "name": "Kitchen"}, {"area_id": "old", "name": "Old"}])
    desired = state(areas={"kitchen": area("Old Kitchen"), "galley": area("Kitchen")}, prune=["areas"])
    p = plan(desired, run(read_live(ha, desired)))
    assert [s.description for s in steps(p)] == [
        "delete areas.old",
        "free the name of areas.kitchen",
        "create areas.galley",
        "name areas.galley",
        "update areas.kitchen",
    ]


def test_pruning_a_floor_that_an_undeclared_area_uses_is_a_problem():
    ha = FakeHA(floors=[{"floor_id": "upstairs", "name": "Upstairs"}], areas=[{"area_id": "bedroom", "name": "Bedroom", "floor_id": "upstairs"}])
    p = plan(state(floors={}, prune=["floors"]), run(read_live(ha, state(floors={}, prune=["floors"]))))
    assert any("clears the floor of the area 'bedroom'" in x for x in p.problems)


def test_pruning_a_label_that_a_kept_area_carries_is_a_problem():
    ha = FakeHA(labels=[{"label_id": "lights", "name": "Lights"}], areas=[{"area_id": "bedroom", "name": "Bedroom", "labels": ["lights"]}])
    desired = state(labels={}, areas={}, prune=["labels"])
    p = plan(desired, run(read_live(ha, desired)))
    assert any("removes it from the area 'bedroom'" in x for x in p.problems)


def test_pruning_a_label_notes_entities_and_devices():
    ha = FakeHA(
        labels=[{"label_id": "lights", "name": "Lights"}],
        entities=[{"entity_id": "light.a", "labels": ["lights"]}, {"entity_id": "light.b", "labels": []}],
        devices=[{"id": "d1", "labels": ["lights"]}],
    )
    desired = state(labels={}, prune=["labels"])
    p = plan(desired, run(read_live(ha, desired)))
    assert p.problems == []
    change = next(c for c in p.actions if c.address == "labels.lights")
    assert change.notes == ["also removes the label from 1 entities and 1 devices"]


def test_categories_in_unnamed_scopes_are_managed():
    ha = FakeHA(categories={"automation": [{"category_id": "01X", "name": "Lighting"}], "script": [{"category_id": "01Y", "name": "Old"}]},
                entities=[{"entity_id": "automation.a", "labels": [], "categories": {"script": "01Y"}}])
    kept = plan(state(categories={}), run(read_live(ha, state(categories={}))))
    assert sorted(c.address for c in kept.changes) == ["categories.automation.01X", "categories.script.01Y"]
    desired = state(categories={"automation": {"lighting": {"name": "Lighting", "icon": None}}}, prune=["categories"])
    pruned = plan(desired, run(read_live(ha, desired)))
    delete = next(c for c in pruned.actions if c.action == "delete")
    assert delete.address == "categories.script.01Y" and delete.notes == ["also removes the category from 1 entities"]
    _, after = run(converge(ha, desired))
    assert after.actions == [] and ha.categories["script"] == {}


def test_failed_rename_after_create_is_reported():
    class FailingRename(FakeHA):
        async def call(self, command, **fields):
            if command.endswith("/update") and fields.get("name") == "Office":
                raise RuntimeError("boom")
            return await super().call(command, **fields)

    ha = FailingRename()
    desired = state(areas={"office": area("Office")})
    p = plan(desired, run(read_live(ha, desired)))
    with pytest.raises(ApplyError) as err:
        run(apply(ha, p, log=lambda _: None))
    assert err.value.done == ["create areas.office"]
