import models.frontend.state as hstate

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
