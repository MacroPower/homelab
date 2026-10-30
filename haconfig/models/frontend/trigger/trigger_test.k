import runtime

test_same_shape_triggers_dispatch_by_value = lambda {
    _sun = coerce({trigger = "sun", event = "sunset"})
    _ha = coerce({trigger = "homeassistant", event = "start"})
    assert typeof(_sun) == "SunTrigger" and typeof(_ha) == "HomeAssistantTrigger"
}

test_every_classic_trigger_dispatches = lambda {
    _cases = {
        StateTrigger = {trigger = "state", entity_id = "a.b", to = "on"}
        NumericStateTrigger = {trigger = "numeric_state", entity_id = "sensor.t", above = 20}
        TimeTrigger = {trigger = "time", at = ["07:30", "input_datetime.wake", {entity_id = "sensor.alarm", offset = "-00:05:00"}]}
        TimePatternTrigger = {trigger = "time_pattern", minutes = "/5"}
        EventTrigger = {trigger = "event", event_type = "my_event"}
        TemplateTrigger = {trigger = "template", value_template = "{{ true }}"}
        MqttTrigger = {trigger = "mqtt", topic = "a/b", qos = 1}
        WebhookTrigger = {trigger = "webhook", webhook_id = "hook", allowed_methods = ["POST"]}
        ZoneTrigger = {trigger = "zone", entity_id = "person.me", zone = "zone.home"}
    }
    _got = {_k = typeof(coerce(_v)) for _k, _v in _cases}
    assert all _k, _v in _got { _k == _v }, "got: ${_got}"
}

test_purpose_trigger = lambda {
    _t = coerce({trigger = "motion.detected", target.entity_id = "binary_sensor.x", options.behavior = "each"})
    assert typeof(_t) == "PurposeTrigger"
}

test_instance_passes_through = lambda {
    _raw = coerce(RawTrigger {trigger = "tag", tag_id = "door"})
    _state = coerce(StateTrigger {entity_id = "a.b"})
    assert typeof(_raw) == "RawTrigger" and typeof(_state) == "StateTrigger"
}

test_missing_required_does_not_fall_through = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "state", target.entity_id = "a.b"}
        coerce(_t)
    })
    assert "No attribute named 'target'" in _err or "entity_id" in _err, "got: ${_err}"
}

test_unknown_platform_rejected = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "tag", tag_id = "x"}
        coerce(_t)
    })
    assert "unknown trigger `tag`; use trigger.RawTrigger" in _err, "got: ${_err}"
}

test_legacy_platform_rejected = lambda {
    _err = runtime.catch(lambda {
        _t: any = {platform = "state", entity_id = "a.b"}
        coerce(_t)
    })
    assert "legacy `platform:`" in _err, "got: ${_err}"
}

test_primitive_rejected = lambda {
    _err = runtime.catch(lambda {
        _t: any = "state"
        coerce(_t)
    })
    assert "a trigger must be a mapping, got str" in _err, "got: ${_err}"
}

test_legacy_behavior_rejected = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "light.turned_on", options.behavior = "any"}
        coerce(_t)
    })
    assert "2027.1" in _err, "got: ${_err}"
}

test_to_null_is_kept = lambda {
    _t = coerce({trigger = "state", entity_id = "a.b", to = None})
    assert "to" in _t and _t.to == None
}

test_state_trigger_exclusive_fields = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "state", entity_id = "a.b", to = "on", not_to = "off"}
        coerce(_t)
    })
    assert "`to` and `not_to` are mutually exclusive" in _err, "got: ${_err}"
}

test_bad_time_rejected = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "time", at = "7pm"}
        coerce(_t)
    })
    assert "time trigger `at` must be HH:MM[:SS]" in _err, "got: ${_err}"
}

test_catalog_rejects_unknown_purpose_trigger = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "motion.detectedd", target.entity_id = "binary_sensor.m"}
        coerce(_t)
    })
    assert "unknown trigger `motion.detectedd` (not in the Home Assistant ${HA_VERSION} catalog)" in _err, "got: ${_err}"
}

test_catalog_rejects_unknown_option = lambda {
    _err = runtime.catch(lambda {
        _t: any = {trigger = "motion.detected", target.entity_id = "binary_sensor.m", options.behaviour = "each"}
        coerce(_t)
    })
    assert "unknown option(s) [behaviour]" in _err, "got: ${_err}"
}

test_purpose_trigger_without_target = lambda {
    _t = coerce({trigger = "sun.sunset", options.offset = "-00:30:00"})
    assert typeof(_t) == "PurposeTrigger"
}

test_state_trigger_null_from_with_not_from_rejected = lambda {
    _err = runtime.catch(lambda {
        coerce({trigger = "state", entity_id = "light.a", from = None, not_from = "off"})
    })
    assert "`from` and `not_from` are mutually exclusive" in _err, "got: ${_err}"
}

test_state_trigger_entity_id_checked = lambda {
    _err = runtime.catch(lambda {
        coerce({trigger = "state", entity_id = "light_a"})
    })
    assert "state trigger `entity_id` must be entity ids, got `light_a`" in _err, "got: ${_err}"
}

test_state_trigger_for_checked = lambda {
    _err = runtime.catch(lambda {
        coerce({trigger = "state", entity_id = "light.a", $for = "5 minutes"})
    })
    assert "state trigger `for` must be HH:MM[:SS]" in _err, "got: ${_err}"
}

test_time_trigger_hour_range_checked = lambda {
    _err = runtime.catch(lambda {
        coerce({trigger = "time", at = "25:00"})
    })
    assert "time trigger `at` must be HH:MM[:SS]" in _err, "got: ${_err}"
}

test_time_trigger_weekday_checked = lambda {
    _err = runtime.catch(lambda {
        coerce({trigger = "time", at = "07:00", weekday = "monday"})
    })
    assert "expect \"mon\"" in _err, "got: ${_err}"
}
