import json

import models.frontend.state as hstate

# encoded returns `v` as the engine reads it, without its Undefined values.
encoded = lambda v: any -> any {
    json.decode(json.encode(v))
}

test_unset_fields_become_empty = lambda {
    _data = StateBackend(hstate.State {
        floors.ground = {name = "Ground", level = 0}
        areas.hall = {name = "Hall"}
        labels.lights = {name = "Lights"}
        categories.automation.lighting = {name = "Lighting"}
    }).data
    assert _data.format == 1 and _data.generator == "haconfig", "got: ${_data}"
    assert _data.floors.ground == {name = "Ground", level = 0, icon = None, aliases = []}, "got: ${_data.floors}"
    assert _data.areas.hall == {name = "Hall", floor_id = None, icon = None, aliases = [], labels = [], picture = None, temperature_entity_id = None, humidity_entity_id = None}, "got: ${_data.areas}"
    assert _data.labels.lights == {name = "Lights", color = None, icon = None, description = None}, "got: ${_data.labels}"
    assert _data.categories.automation.lighting == {name = "Lighting", icon = None}, "got: ${_data.categories}"
    assert _data.prune == [], "got: ${_data}"
}

test_unset_collections_stay_unmanaged = lambda {
    _data = StateBackend(hstate.State {areas = {}, prune = ["areas"]}).data
    assert "floors" not in _data and "labels" not in _data and "categories" not in _data, "got: ${_data}"
    assert _data.areas == {} and _data.prune == ["areas"], "got: ${_data}"
}

test_area_fields_map_to_registry_names = lambda {
    _a = StateBackend(hstate.State {
        areas.hall = {name = "Hall", floor = "ground", temperatureEntity = "sensor.t", humidityEntity = "sensor.h"}
    }).data.areas.hall
    assert _a.floor_id == "ground" and _a.temperature_entity_id == "sensor.t" and _a.humidity_entity_id == "sensor.h", "got: ${_a}"
}

test_settings_collections_carry_only_set_fields = lambda {
    _data = StateBackend(hstate.State {
        devices.lamp = {match.id = "0123456789abcdef0123456789abcdef", area = None}
        entities = {"light.lamp" = {name = "Lamp", match = {platform = "hue", uniqueId = "abc"}}}
        integrations.hue = {domain = "hue", title = "Hue"}
    }).data
    assert encoded(_data.devices.lamp) == {match = {id = "0123456789abcdef0123456789abcdef"}, area_id = None}, "got: ${_data.devices}"
    assert encoded(_data.entities["light.lamp"]) == {match = {platform = "hue", unique_id = "abc"}, name = "Lamp"}, "got: ${_data.entities}"
    assert encoded(_data.integrations.hue) == {domain = "hue", title = "Hue"}, "got: ${_data.integrations}"
}

test_apps_and_hacs_map_to_engine_names = lambda {
    _data = StateBackend(hstate.State {
        apps.core_ssh = {options = {apks = []}, autoUpdate = False, ingressPanel = True}
        appRepositories = ["https://github.com/hacs/addons"]
        hacs = {"hacs/integration" = {category = "integration", version = "2.0.5"}}
        prune = ["appRepositories", "apps"]
    }).data
    assert encoded(_data.apps.core_ssh) == {options = {apks = []}, auto_update = False, ingress_panel = True}, "got: ${_data.apps}"
    assert _data.app_repositories == ["https://github.com/hacs/addons"], "got: ${_data}"
    assert _data.hacs["hacs/integration"] == {category = "integration", version = "2.0.5"}, "got: ${_data.hacs}"
    assert _data.prune == ["app_repositories", "apps"], "got: ${_data.prune}"
}

test_none_entries_drop_out = lambda {
    _data = encoded(StateBackend(hstate.State {
        floors = {ground = {name = "Ground"}, attic = None}
        apps = {core_ssh = {}, core_gone = None}
    }).data)
    assert list(_data.floors) == ["ground"], "got: ${_data.floors}"
    assert list(_data.apps) == ["core_ssh"], "got: ${_data.apps}"
}
