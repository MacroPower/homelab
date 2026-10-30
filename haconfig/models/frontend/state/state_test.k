import runtime

test_valid_state = lambda {
    _s = State {
        floors.ground = {name = "Ground Floor", level = 0, aliases = ["Downstairs"]}
        areas.living_room = {name = "Living Room", floor = "ground", labels = ["lights"], temperatureEntity = "sensor.living_room_temperature"}
        labels.lights = {name = "Lights", color = "#FFAA00"}
        labels.critical = {name = "Critical", color = "red"}
        categories.automation.lighting = {name = "Lighting"}
        prune = ["areas", "labels"]
    }
    assert len(_s.areas) == 1
}

test_keys_must_be_slugs = lambda {
    _err = runtime.catch(lambda {
        _k: any = "Living Room"
        State {areas = {"${_k}" = {name = "Living Room"}}}
    })
    assert "state keys must be slugs, got [areas.Living Room]" in _err, "got: ${_err}"
}

test_category_scope_must_be_slug = lambda {
    _err = runtime.catch(lambda {
        _s: any = "My Scope"
        State {categories = {"${_s}" = {lighting = {name = "Lighting"}}}}
    })
    assert "got [categories.My Scope]" in _err, "got: ${_err}"
}

test_prune_needs_managed_collection = lambda {
    _unknown = runtime.catch(lambda {
        _p: any = ["rooms"]
        State {areas = {}, prune = _p}
    })
    _unmanaged = runtime.catch(lambda {
        _p: any = ["floors"]
        State {areas = {}, prune = _p}
    })
    assert "got [rooms]" in _unknown, "got: ${_unknown}"
    assert "got [floors]" in _unmanaged, "got: ${_unmanaged}"
}

test_duplicate_names_ignore_case_and_whitespace = lambda {
    _areas = runtime.catch(lambda {
        _n: any = "living room"
        State {areas = {a = {name = "Living Room"}, b = {name = _n}}}
    })
    _categories = runtime.catch(lambda {
        _n: any = "LIGHTING"
        State {categories.automation = {a = {name = "Lighting"}, b = {name = _n}}}
    })
    assert "areas: livingroom" in _areas, "got: ${_areas}"
    assert "categories.automation: lighting" in _categories, "got: ${_categories}"
}

test_label_color = lambda {
    _err = runtime.catch(lambda {
        _c: any = "#FFF"
        Label {name = "Lights", color = _c}
    })
    assert "color must be #RRGGBB" in _err, "got: ${_err}"
}

test_area_field_checks = lambda {
    _floor = runtime.catch(lambda {
        _f: any = "Ground Floor"
        Area {name = "Hall", floor = _f}
    })
    _labels = runtime.catch(lambda {
        _l: any = ["Lights"]
        Area {name = "Hall", labels = _l}
    })
    _temperature = runtime.catch(lambda {
        _t: any = "climate.hall"
        Area {name = "Hall", temperatureEntity = _t}
    })
    _aliases = runtime.catch(lambda {
        _a: any = [" "]
        Area {name = "Hall", aliases = _a}
    })
    assert "floor must be a floor id" in _floor, "got: ${_floor}"
    assert "labels must be label ids, got [Lights]" in _labels, "got: ${_labels}"
    assert "temperatureEntity must be a sensor entity id" in _temperature, "got: ${_temperature}"
    assert "aliases must not be empty strings" in _aliases, "got: ${_aliases}"
}
