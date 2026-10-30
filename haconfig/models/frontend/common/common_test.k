import runtime

test_is_slug = lambda {
    assert isSlug("hallway_light")
    assert isSlug("light2")
    assert not isSlug("hallLight")
    assert not isSlug("hall-light")
    assert not isSlug("_hall")
    assert not isSlug("hall_")
    assert not isSlug("hall__light")
    assert not isSlug("")
}

test_is_entity_ids = lambda {
    assert isEntityIds("light.hallway")
    assert isEntityIds(["light.hallway", "sensor.lux_2"])
    assert isEntityIds("all")
    assert isEntityIds("none")
    assert isEntityIds("{{ targets }}")
    assert not isEntityIds("Light.Hallway")
    assert not isEntityIds("light")
    assert not isEntityIds("light._hallway")
    assert not isEntityIds("light.hall__way")
    assert not isEntityIds(["light.hallway", 3])
}

test_slugify = lambda {
    assert slugify("Hallway motion light") == "hallway_motion_light"
    assert slugify("  Kitchen -- TV off! ") == "kitchen_tv_off"
}

test_humanize = lambda {
    assert humanize("motion_light") == "Motion light"
    assert humanize("lux") == "Lux"
}

test_as_list = lambda {
    assert asList("a") == ["a"]
    assert asList(["a", "b"]) == ["a", "b"]
}

test_target_rejects_bad_entity_id = lambda {
    _ok = Target {entity_id = ["light.a", "light.b"], area_id = "hallway"}
    _err = runtime.catch(lambda {
        _t: any = {entity_id = "Light.Hallway"}
        Target {**_t}
    })
    assert "target `entity_id` must be entity ids" in _err, "got: ${_err}"
}

test_is_entity_ids_accepts_registry_ids = lambda {
    assert isEntityIds("0123456789abcdef0123456789abcdef")
    assert not isEntityIds("light_a")
}

test_is_duration = lambda {
    assert isDuration("00:05:00") and isDuration("-00:30") and isDuration("00:00:01.5")
    assert isDuration("90") and isDuration(90) and isDuration({minutes = 1}) and isDuration("{{ x }}")
    assert isDuration(Undefined)
    assert not isDuration("5 minutes")
}
