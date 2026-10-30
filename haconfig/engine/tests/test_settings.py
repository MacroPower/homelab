from __future__ import annotations

import asyncio

from fakeha import FakeHA

from hastate.apply import apply, steps
from hastate.live import read_live
from hastate.plan import plan

LAMP = "0" * 31 + "1"
HUB = "0" * 31 + "2"


def state(**collections: object) -> dict[str, object]:
    return {"format": 1, "prune": [], **collections}


def run(coro):
    return asyncio.run(coro)


def planned(ha: FakeHA, desired: dict):
    return plan(desired, run(read_live(ha, desired)))


def converge(ha: FakeHA, desired: dict):
    before = planned(ha, desired)
    assert before.problems == [], before.problems
    run(apply(ha, before, log=lambda _: None))
    after = planned(ha, desired)
    return before, after


def home() -> FakeHA:
    return FakeHA(
        areas=[{"area_id": "hall", "name": "Hall"}, {"area_id": "den", "name": "Den"}],
        labels=[{"label_id": "lights", "name": "Lights"}],
        categories={"automation": [{"category_id": "01A", "name": "Lighting"}]},
        devices=[
            {"id": LAMP, "name": "Hue lamp", "identifiers": [["hue", "abc-1"]], "connections": [["mac", "AA:BB:CC:00:00:01"]]},
            {"id": HUB, "name": "Bridge", "identifiers": [["hue", "bridge"]], "disabled_by": "config_entry"},
        ],
        entities=[
            {"entity_id": "light.hue_lamp", "id": "e1", "platform": "hue", "unique_id": "abc-1-light", "device_id": LAMP, "original_name": None},
            {"entity_id": "sensor.hue_lamp_power", "id": "e2", "platform": "hue", "unique_id": "abc-1-power", "device_id": LAMP, "original_name": "Power"},
            {"entity_id": "automation.night", "id": "e3", "platform": "automation", "unique_id": "night", "original_name": "Night"},
            {"entity_id": "switch.fan", "id": "e4", "platform": "demo", "unique_id": "fan", "device_id": HUB, "disabled_by": "device", "original_name": "Fan"},
        ],
        entries=[
            {"entry_id": "01HUE", "domain": "hue", "title": "Hue Bridge"},
            {"entry_id": "01MET", "domain": "met", "title": "Home"},
            {"entry_id": "01IGN", "domain": "zha", "title": "Ignored", "source": "ignore"},
        ],
    )


def test_device_matches_by_id_identifier_and_connection():
    for match in ({"id": LAMP}, {"identifier": ["hue", "abc-1"]}, {"connection": ["mac", "aa:bb:cc:00:00:01"]}):
        result = planned(home(), state(devices={"lamp": {"match": match, "area_id": "hall"}}))
        assert result.problems == [] and [c.target for c in result.actions] == [LAMP], match


def test_device_match_must_find_one_device():
    result = planned(home(), state(devices={"lamp": {"match": {"identifier": ["hue", "missing"]}}}))
    assert any("finds 0 devices" in p for p in result.problems)


def test_device_settings_converge_and_leave_unset_fields():
    ha = home()
    ha.devices[0]["name_by_user"] = "Keep me"
    before, after = converge(ha, state(devices={"lamp": {"match": {"id": LAMP}, "area_id": "hall", "labels": ["lights"], "disabled": True}}))
    assert before.actions[0].diff == {"area_id": (None, "hall"), "labels": ([], ["lights"]), "disabled_by": (None, "user")}
    assert after.actions == []
    assert ha.devices[0]["name_by_user"] == "Keep me"
    assert ha.entities[0]["disabled_by"] == "device"


def test_device_flag_set_by_config_entry_is_a_warning():
    result = planned(home(), state(devices={"hub": {"match": {"id": HUB}, "disabled": False}}))
    assert result.actions == [] and any("disabled_by is 'config_entry'" in w for w in result.warnings)


def test_device_area_must_exist():
    result = planned(home(), state(devices={"lamp": {"match": {"id": LAMP}, "area_id": "attic"}}))
    assert any("area 'attic' does not exist" in p for p in result.problems)


def test_entity_rename_and_fields_converge():
    ha = home()
    desired = state(
        categories={"automation": {"lighting": {"name": "Lighting", "icon": None}, "night": {"name": "Night", "icon": None}}},
        entities={
            "sensor.lamp_power": {"match": {"platform": "hue", "unique_id": "abc-1-power"}, "area_id": "den", "aliases": ["Lamp watts"], "device_class": "power"},
            "automation.night": {"categories": {"automation": "Night"}, "labels": ["lights"], "hidden": True},
        },
    )
    before, after = converge(ha, desired)
    rename = next(c for c in before.actions if c.address == "entities.sensor.lamp_power")
    assert rename.diff["entity_id"] == ("sensor.hue_lamp_power", "sensor.lamp_power")
    assert after.actions == [] and after.problems == []
    by_id = {e["entity_id"]: e for e in ha.entities}
    assert by_id["sensor.lamp_power"]["aliases"] == ["Lamp watts"] and by_id["sensor.lamp_power"]["device_class"] == "power"
    night = [c["category_id"] for c in ha.categories["automation"].values() if c["name"] == "Night"]
    assert by_id["automation.night"]["categories"] == {"automation": night[0]}
    assert by_id["automation.night"]["hidden_by"] == "user"


def test_entity_categories_map_is_whole():
    ha = home()
    ha.entities[2]["categories"] = {"automation": "01A", "script": "01X"}
    _, after = converge(ha, state(entities={"automation.night": {"categories": {}}}))
    assert after.actions == [] and ha.entities[2]["categories"] == {}


def test_entity_problems():
    result = planned(
        home(),
        state(
            entities={
                "light.hue_lamp": {"area_id": "den"},
                "switch.fan": {"disabled": False},
                "light.nope": {"name": "Nope"},
                "light.taken": {"match": {"platform": "hue", "unique_id": "abc-1-light"}},
                "sensor.hue_lamp_power": {"match": {"platform": "automation", "unique_id": "night"}},
                "automation.night": {"categories": {"automation": "Missing"}},
            }
        ),
    )
    text = "\n".join(result.problems)
    assert "entities.light.hue_lamp: an entity without a name of its own cannot have an area of its own" in text
    assert "entities.switch.fan: its device stays disabled" in text
    assert "entities.light.nope: the entity registry has no 'light.nope'" in text
    assert "entities.sensor.hue_lamp_power: no sensor entity of platform 'automation' has the unique id 'night'" in text
    assert "category 'Missing' does not exist" in text


def test_entity_with_own_name_can_have_own_area():
    ha = home()
    _, after = converge(ha, state(entities={"light.hue_lamp": {"name": "Lamp", "area_id": "den"}}))
    assert after.actions == []


def test_integrations_inventory():
    ha = home()
    desired = state(
        integrations={
            "hue": {"domain": "hue", "entry_id": "01HUE", "title": "Hue", "pref_disable_polling": True},
            "esphome": {"domain": "esphome", "title": "Garage"},
        }
    )
    result = planned(ha, desired)
    by_address = {c.address: c for c in result.changes}
    assert by_address["integrations.hue"].diff == {"title": ("Hue Bridge", "Hue"), "pref_disable_polling": (False, True)}
    assert by_address["integrations.esphome"].action == "missing"
    assert by_address["integrations.01MET"].action == "unmanaged"
    assert "integrations.01IGN" not in by_address
    assert any("add the integration in the UI" in w for w in result.warnings)
    run(apply(ha, result, log=lambda _: None))
    assert planned(ha, desired).actions == []


def test_integration_disable_runs_its_own_step():
    result = planned(home(), state(integrations={"met": {"domain": "met", "title": "Home", "disabled": True}}))
    assert [(s.command, s.fields) for s in steps(result)] == [("config_entries/disable", {"entry_id": "01MET", "disabled_by": "user"})]


def test_entity_enable_follows_the_final_device_state():
    ha = home()
    ha.devices[0]["disabled_by"] = "user"
    ha.entities[1]["disabled_by"] = "user"
    stays = planned(ha, state(entities={"sensor.hue_lamp_power": {"disabled": False}}))
    assert any("its device stays disabled" in p for p in stays.problems)
    both = state(devices={"lamp": {"match": {"id": LAMP}, "disabled": False}}, entities={"sensor.hue_lamp_power": {"disabled": False}})
    _, after = converge(ha, both)
    assert after.actions == [] and ha.entities[1]["disabled_by"] is None


def test_entity_aliases_keep_the_placeholder_and_strip():
    ha = home()
    ha.entities[0]["aliases"] = ["Kitchen", None]
    result = planned(ha, state(entities={"light.hue_lamp": {"aliases": [" Kitchen ", "Cooking"]}}))
    change = result.actions[0]
    assert change.diff["aliases"] == (["Kitchen"], ["Kitchen", "Cooking"])
    assert steps(result)[0].fields["aliases"] == ["Kitchen", None, "Cooking"]
    run(apply(ha, result, log=lambda _: None))
    assert planned(ha, state(entities={"light.hue_lamp": {"aliases": [" Kitchen ", "Cooking"]}})).actions == []
    cleared = planned(ha, state(entities={"light.hue_lamp": {"aliases": [], "categories": {}, "labels": []}}))
    assert steps(cleared)[0].fields["aliases"] == [None]


def test_entity_match_uses_the_domain():
    ha = home()
    ha.entities.append({"entity_id": "binary_sensor.hall", "id": "e5", "platform": "template", "unique_id": "hall", "original_name": "Hall"})
    ha.entities.append({"entity_id": "sensor.hall", "id": "e6", "platform": "template", "unique_id": "hall", "original_name": "Hall"})
    result = planned(ha, state(entities={"sensor.hall_temp": {"match": {"platform": "template", "unique_id": "hall"}}}))
    assert result.problems == [] and result.actions[0].diff == {"entity_id": ("sensor.hall", "sensor.hall_temp")}


def test_integration_none_fields_are_problems():
    result = planned(home(), state(integrations={"hue": {"domain": "hue", "entry_id": "01HUE", "title": None}}))
    assert any("title is None" in p for p in result.problems)


def test_entity_enable_blocked_when_the_plan_disables_its_device():
    result = planned(home(), state(devices={"lamp": {"match": {"id": LAMP}, "disabled": True}}, entities={"sensor.hue_lamp_power": {"disabled": False}}))
    assert any("its device stays disabled" in p for p in result.problems)


def test_entity_disable_with_the_device_enable_converges_in_one_apply():
    ha = home()
    ha.devices[0]["disabled_by"] = "user"
    ha.entities[1]["disabled_by"] = "device"
    desired = state(devices={"lamp": {"match": {"id": LAMP}, "disabled": False}}, entities={"sensor.hue_lamp_power": {"disabled": True}})
    before, after = converge(ha, desired)
    assert after.actions == [] and ha.entities[1]["disabled_by"] == "user"


def test_entity_enable_with_the_integration_enable():
    ha = home()
    ha.entries[0]["disabled_by"] = "user"
    ha.devices[0].update({"disabled_by": "config_entry", "config_entries": ["01HUE"]})
    ha.entities[1]["disabled_by"] = "user"
    desired = state(integrations={"hue": {"domain": "hue", "entry_id": "01HUE", "disabled": False}}, entities={"sensor.hue_lamp_power": {"disabled": False}})
    before, after = converge(ha, desired)
    assert after.actions == [] and ha.entities[1]["disabled_by"] is None


def test_stale_device_flag_clears():
    ha = home()
    ha.entities[1]["disabled_by"] = "device"
    result = planned(ha, state(entities={"sensor.hue_lamp_power": {"disabled": False}}))
    assert result.problems == [] and result.actions[0].diff == {"disabled_by": ("device", None)}
