import models.frontend

test_empty_helper_emits_null = lambda {
    _hass = PackageBackend(frontend.Package {
        name = "p"
        inputBooleans.b = {}
        inputBooleans.named = {name = "Named"}
        inputButtons.btn = {}
        timers.t = {}
        counters.c = {}
    }).hass
    assert _hass.input_boolean.b == None and _hass.input_boolean.named.name == "Named", "got: ${_hass}"
    assert _hass.input_button.btn == None and _hass.timer.t == None and _hass.counter.c == None, "got: ${_hass}"
}

test_empty_selector_and_field_survive_package_merge = lambda {
    _hass = PackageBackend(frontend.Package {
        name = "p"
        scripts.s = {
            sequence = [{delay = 1}]
            fields.flag.selector.boolean = {}
            fields.bare = {}
            fields.level.selector.number = {min = 1}
        }
    }).hass
    _fields = _hass.script.s.fields
    assert _fields.flag.selector.boolean == None, "got: ${_fields}"
    assert _fields.bare.required == False, "got: ${_fields}"
    assert _fields.level.selector.number.min == 1, "got: ${_fields}"
}

test_deleted_template_entities_drop_their_section = lambda {
    _p = frontend.Package {
        name = "p"
        templates.lux.sensors.lux = {state = "{{ 1 }}"}
        templates.lux.binarySensors.dark = {state = "{{ true }}"}
        templates.temp.sensors.temp = {state = "{{ 2 }}"}
    }
    _hass = PackageBackend(_p | {templates.lux.sensors.lux = Undefined, templates.lux.binarySensors.dark = Undefined}).hass
    assert len(_hass.template) == 1 and _hass.template[0].sensor[0].unique_id == "p.temp", "got: ${_hass}"
}

test_deleted_last_helper_emits_no_domain = lambda {
    _p = frontend.Package {name = "p", timers.t = {duration = "00:01:00"}}
    _hass = PackageBackend(_p | {timers.t = Undefined}).hass
    assert "timer" not in _hass, "got: ${_hass}"
}
