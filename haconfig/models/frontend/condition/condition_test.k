import runtime

test_logic_conditions_dispatch = lambda {
    _nested = [{condition = "state", entity_id = "a.b", state = "on"}]
    _and = coerce({condition = "and", conditions = _nested})
    _or = coerce({condition = "or", conditions = _nested})
    _not = coerce({condition = "not", conditions = _nested})
    assert typeof(_and) == "LogicCondition" and _and.condition == "and"
    assert typeof(_or) == "LogicCondition" and _or.condition == "or"
    assert typeof(_not) == "LogicCondition" and _not.condition == "not"
}

test_every_classic_condition_dispatches = lambda {
    _cases = {
        StateCondition = {condition = "state", entity_id = "a.b", state = "on"}
        NumericStateCondition = {condition = "numeric_state", entity_id = "sensor.t", below = 30}
        TemplateCondition = {condition = "template", value_template = "{{ true }}"}
        TimeCondition = {condition = "time", after = "07:00", weekday = ["mon", "tue"]}
        TriggerCondition = {condition = "trigger", id = "motion"}
        SunCondition = {condition = "sun", after = "sunset"}
        ZoneCondition = {condition = "zone", entity_id = "person.me", zone = "zone.home"}
        PurposeCondition = {condition = "light.is_on", target.entity_id = "light.hallway"}
    }
    _got = {_k = typeof(coerce(_v)) for _k, _v in _cases}
    assert all _k, _v in _got { _k == _v }, "got: ${_got}"
}

test_template_shorthand_passes_through = lambda {
    assert coerce("{{ is_state('a.b', 'on') }}") == "{{ is_state('a.b', 'on') }}"
    _err = runtime.catch(lambda {
        _c: any = "is_state"
        coerce(_c)
    })
    assert "a string condition must be a template" in _err, "got: ${_err}"
}

test_key_shorthand_rejected = lambda {
    _err = runtime.catch(lambda {
        _c: any = {"or" = [{condition = "state", entity_id = "a.b", state = "on"}]}
        coerce(_c)
    })
    assert "write `condition: and` rather than the `and:` shorthand" in _err, "got: ${_err}"
}

test_nested_typo_fails = lambda {
    _err = runtime.catch(lambda {
        _c: any = {condition = "not", conditions = [{condition = "state", entity_id = "a.b", state = "on", atribute = "x"}]}
        coerce(_c)
    })
    assert "No attribute named 'atribute'" in _err, "got: ${_err}"
}

test_unknown_condition_rejected = lambda {
    _err = runtime.catch(lambda {
        _c: any = {condition = "device", device_id = "x"}
        coerce(_c)
    })
    assert "unknown condition `device`; use condition.RawCondition" in _err, "got: ${_err}"
}

test_raw_passes_through = lambda {
    _c = coerce(RawCondition {condition = "device", device_id = "x", domain = "light", type = "is_on"})
    assert typeof(_c) == "RawCondition"
}

test_state_for_excludes_attribute = lambda {
    _err = runtime.catch(lambda {
        _c: any = {condition = "state", entity_id = "a.b", state = "on", attribute = "x", $for = 5}
        coerce(_c)
    })
    assert "state condition `for` cannot be combined with `attribute`" in _err, "got: ${_err}"
}

test_required_fields_checked = lambda {
    _numeric = runtime.catch(lambda {
        _c: any = {condition = "numeric_state", entity_id = "sensor.t"}
        coerce(_c)
    })
    _time = runtime.catch(lambda {
        _c: any = {condition = "time"}
        coerce(_c)
    })
    _sun = runtime.catch(lambda {
        _c: any = {condition = "sun"}
        coerce(_c)
    })
    assert "needs `above` or `below`" in _numeric, "got: ${_numeric}"
    assert "time condition needs `after`, `before` or `weekday`" in _time, "got: ${_time}"
    assert "sun condition needs `after` or `before`" in _sun, "got: ${_sun}"
}

test_catalog_rejects_unknown_name = lambda {
    _err = runtime.catch(lambda {
        _c: any = {condition = "light.is_onn", target.entity_id = "light.hallway"}
        coerce(_c)
    })
    assert "unknown condition `light.is_onn` (not in the Home Assistant ${HA_VERSION} catalog)" in _err, "got: ${_err}"
}

test_catalog_rejects_unknown_option = lambda {
    _err = runtime.catch(lambda {
        _c: any = {condition = "light.is_on", target.entity_id = "light.hallway", options.behaviour = "any"}
        coerce(_c)
    })
    assert "unknown option(s) [behaviour]" in _err, "got: ${_err}"
}

test_catalog_rejects_bad_behavior = lambda {
    _err = runtime.catch(lambda {
        _c: any = {condition = "light.is_on", target.entity_id = "light.hallway", options.behavior = "each"}
        coerce(_c)
    })
    assert "condition `behavior` must be `any` or `all`" in _err, "got: ${_err}"
}

test_state_condition_state_must_be_string = lambda {
    _err = runtime.catch(lambda {
        coerce({condition = "state", entity_id = "light.a", state = 5})
    })
    assert "state condition `state` must be a string" in _err, "got: ${_err}"
}

test_state_condition_attribute_state_any = lambda {
    _c = coerce({condition = "state", entity_id = "light.a", attribute = "brightness", state = 5})
    assert typeof(_c) == "StateCondition"
}

test_state_condition_for_with_helper_state_rejected = lambda {
    _err = runtime.catch(lambda {
        coerce({condition = "state", entity_id = "light.a", state = "input_select.mode", $for = 5})
    })
    assert "cannot be combined with a `state` that names an `input_*` helper" in _err, "got: ${_err}"
}

test_time_condition_after_checked = lambda {
    _err = runtime.catch(lambda {
        coerce({condition = "time", after = "25:00"})
    })
    assert "time condition `after` must be HH:MM[:SS]" in _err, "got: ${_err}"
}
