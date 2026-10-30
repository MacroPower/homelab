import runtime

test_state_based_section = lambda {
    _s = TemplateSection {
        sensors.lux = {state = "{{ 1 }}", unit_of_measurement = "lx"}
        binarySensors.dark = {state = "{{ true }}", delay_on.seconds = 5}
        switches.fan = {turn_on = [{action = "fan.turn_on"}], turn_off = [{action = "fan.turn_off"}]}
        buttons.reboot = {press = [{action = "button.press"}]}
        numbers.target = {set_value = [{action = "input_number.set_value"}], min = 0.0, max = 10.0}
        selects.mode = {options = "{{ ['a', 'b'] }}", select_option = [{action = "input_select.select_option"}]}
        entities.weather.home = {condition_template = "{{ 'sunny' }}"}
    }
    assert typeof(_s.entities.weather.home) == "GenericTemplateEntity"
}

test_conditions_require_triggers = lambda {
    _err = runtime.catch(lambda {
        _c: any = [{condition = "template", value_template = "{{ true }}"}]
        TemplateSection {conditions = _c, sensors.s = {state = "1"}}
    })
    assert "template `conditions` and `actions` require `triggers`" in _err, "got: ${_err}"
}

test_trigger_section_rejects_buttons = lambda {
    _err = runtime.catch(lambda {
        _t: any = [{trigger = "time_pattern", minutes = "/5"}]
        TemplateSection {triggers = _t, buttons.b = {press = []}}
    })
    assert "template buttons are not allowed in a trigger-based section" in _err, "got: ${_err}"
}

test_auto_off_requires_triggers = lambda {
    _ok = TemplateSection {triggers = [{trigger = "event", event_type = "doorbell"}], binarySensors.ring = {state = "{{ true }}", auto_off = 5}}
    _err = runtime.catch(lambda {
        _b: any = {state = "{{ true }}", auto_off = 5}
        TemplateSection {binarySensors.ring = _b}
    })
    assert "`auto_off` requires a trigger-based section" in _err, "got: ${_err}"
}

test_entities_rejects_typed_domain = lambda {
    _err = runtime.catch(lambda {
        _e: any = {sensor.y = {state = "1"}}
        TemplateSection {entities = _e}
    })
    assert "use the typed map for [sensor]" in _err, "got: ${_err}"
}

test_entities_rejects_bad_domain = lambda {
    _err = runtime.catch(lambda {
        _e: any = {"Weather" = {y = {}}}
        TemplateSection {entities = _e}
    })
    assert "`entities` keys must be HA domains, got [Weather]" in _err, "got: ${_err}"
}

test_last_reset_requires_total = lambda {
    _ok = TemplateSensor {state = "1", state_class = "total", last_reset = "{{ today_at() }}"}
    _err = runtime.catch(lambda {
        _c: any = "measurement"
        TemplateSensor {state = "1", state_class = _c, last_reset = "{{ today_at() }}"}
    })
    assert "`last_reset` requires `state_class: total`" in _err, "got: ${_err}"
}

test_entity_fields_from_ha = lambda {
    _s = TemplateSection {
        numbers.n = {set_value = [{action = "x.y"}], device_class = "temperature"}
        binarySensors.b = {state = "{{ true }}", unit_of_measurement = "x"}
        sensors.s = {state = "{{ 1 }}", default_entity_id = "sensor.other"}
    }
    assert _s.numbers.n.device_class == "temperature"
    _t = TemplateSection {
        triggers = [{trigger = "time_pattern", minutes = "/5"}]
        sensors.s = {state = "{{ 1 }}", conditions = ["{{ true }}"]}
    }
    assert _t.sensors.s.conditions == ["{{ true }}"]
}

test_entity_conditions_need_triggers = lambda {
    _err = runtime.catch(lambda {
        TemplateSection {sensors.s = {state = "{{ 1 }}", conditions = ["{{ true }}"]}}
    })
    assert "template entity `conditions` require a trigger-based section" in _err, "got: ${_err}"
}

test_default_entity_id_domain_checked = lambda {
    _err = runtime.catch(lambda {
        TemplateSensor {state = "{{ 1 }}", default_entity_id = "binary_sensor.x"}
    })
    assert "template `default_entity_id` must be in the `sensor` domain, got `binary_sensor.x`" in _err, "got: ${_err}"
}
