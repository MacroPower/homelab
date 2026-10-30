import runtime

import models.frontend.trigger

test_camel_key_rejected = lambda {
    _err = runtime.catch(lambda {
        Package {name = "hall", timers.hallLight = {}}
    })
    assert "must be a slug" in _err and "got [hallLight]" in _err, "got: ${_err}"
}

test_template_entity_key_rejected = lambda {
    _err = runtime.catch(lambda {
        Package {name = "hall", templates.lux.sensors.hallLux = {state = "1"}}
    })
    assert "must be a slug" in _err and "hallLux" in _err, "got: ${_err}"
}

test_package_name_must_be_slug = lambda {
    _err = runtime.catch(lambda {
        Package {name = "hall-way"}
    })
    assert "package name must be a slug, got `hall-way`" in _err, "got: ${_err}"
}

test_get_entity_id = lambda {
    _p = Package {name = "hall", timers.hall_light = {}}
    assert _p.getEntityId("timer", "hall_light") == "timer.hall_light"
    _err = runtime.catch(lambda {
        _p.getEntityId("timer", "nope")
    })
    assert "package `hall` has no `timer` entry `nope`" in _err, "got: ${_err}"
}

test_error_names_owner_path = lambda {
    _err = runtime.catch(lambda {
        Package {
            name = "hall"
            automations.motion = {
                triggers = [{trigger = "state", entity_id = "binary_sensor.m", too = "on"}]
                actions = [{action = "light.turn_on"}]
            }
        }
    })
    assert "package `hall` has invalid entries:" in _err, "got: ${_err}"
    assert "automations.motion.triggers[0]: No attribute named 'too' in the schema 'StateTrigger'" in _err, "got: ${_err}"
}

test_every_error_is_reported = lambda {
    _err = runtime.catch(lambda {
        Package {
            name = "p"
            automations.a = {
                triggers = [{trigger = "sun", event = "sunset"}, {trigger = "homeassistant", event = "start"}, {trigger = "tag"}]
                actions = [{delay = 1}, {dleay = 1}]
            }
            scripts.s.sequence = [{$if = ["{{ true }}"], then = [{parallel = [[{delay = 1}, {stop = "x", eror = True}]]}]}]
        }
    })
    assert "automations.a.triggers[2]: unknown trigger `tag`" in _err, "got: ${_err}"
    assert "automations.a.actions[1]: unrecognised action with keys [dleay]" in _err, "got: ${_err}"
    assert "scripts.s.sequence[0]: No attribute named 'eror' in the schema 'StopAction'" in _err, "got: ${_err}"
    assert "triggers[0]" not in _err and "triggers[1]" not in _err, "sun and homeassistant must dispatch by value: ${_err}"
}

test_template_lists_validated = lambda {
    _err = runtime.catch(lambda {
        Package {
            name = "p"
            templates.t = {
                triggers = [{trigger = "time_pattern", minutes = "/5"}]
                conditions = [{condition = "state", entity_id = "a.b"}]
                sensors.s = {state = "1"}
            }
            templates.u.switches.fan = {turn_on = [{dleay = 1}]}
            templates.u.numbers.n = {set_value = [{service = "x.y"}]}
        }
    })
    assert "templates.t.conditions[0]:" in _err, "got: ${_err}"
    assert "templates.u.switches.fan.turn_on[0]: unrecognised action" in _err, "got: ${_err}"
    assert "templates.u.numbers.n.set_value[0]: use `action:`" in _err, "got: ${_err}"
}

test_wrong_family_instance_rejected = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", automations.a = {triggers = [{trigger = "homeassistant", event = "start"}], actions = [trigger.StateTrigger {entity_id = "a.b"}]}}
    })
    assert "a StateTrigger is not an action" in _err, "got: ${_err}"
}

test_package_without_scripts = lambda {
    _p = Package {name = "p", timers.t = {}}
    assert _p.getEntityId("timer", "t") == "timer.t"
}

test_generic_template_entity = lambda {
    _p = Package {
        name = "p"
        templates.forecast.entities.weather.home = {
            name = "Home"
            condition_template = "{{ states('weather.raw') }}"
            temperature_template = "{{ 20 }}"
        }
    }
    assert _p.getEntityId("weather", "home") == "weather.home"
    _err = runtime.catch(lambda {
        Package {name = "p", templates.x.entities.sensor.y = {state = "1"}}
    })
    assert "use the typed map for [sensor]" in _err, "got: ${_err}"
}

test_schedule_overlap_rejected = lambda {
    _ok = Package {name = "p", schedules.heat = {name = "Heat", monday = [{from = "06:00:00", to = "08:00:00"}, {from = "17:00:00", to = "24:00:00"}]}}
    _err = runtime.catch(lambda {
        Package {name = "p", schedules.heat = {name = "Heat", monday = [{from = "06:00:00", to = "09:00:00"}, {from = "08:00:00", to = "10:00:00"}]}}
    })
    assert "must not overlap" in _err, "got: ${_err}"
}

test_extra_config_collision_rejected = lambda {
    _ok = Package {name = "p", extraConfig = {"automation raw" = [{id = "raw"}], mqtt.sensor = []}}
    _err = runtime.catch(lambda {
        Package {name = "p", extraConfig.automation = [{id = "raw"}]}
    })
    assert "extraConfig must not set [automation], a domain this package models" in _err, "got: ${_err}"
}

test_reserved_script_key_rejected = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", scripts.turn_on.sequence = [{delay = 1}]}
    })
    assert "script keys [turn_on] are reserved" in _err, "got: ${_err}"
}

test_automation_needs_trigger = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", automations.a = {triggers = [], actions = [{delay = 1}]}}
    })
    assert "automation needs at least one trigger" in _err, "got: ${_err}"
}

test_automation_max_needs_mode = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", automations.a = {mode = "single", max = 3, triggers = [{trigger = "homeassistant", event = "start"}], actions = [{delay = 1}]}}
    })
    assert "automation `max` only applies to `queued` or `parallel` mode" in _err, "got: ${_err}"
}

test_automation_max_at_least_two = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", automations.a = {mode = "queued", max = 1, triggers = [{trigger = "homeassistant", event = "start"}], actions = [{delay = 1}]}}
    })
    assert "automation `max` must be at least 2" in _err, "got: ${_err}"
}

test_script_icon_checked = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", scripts.s = {icon = "lightbulb", sequence = [{delay = 1}]}}
    })
    assert "icon must look like `mdi:name`" in _err, "got: ${_err}"
}

test_script_max_needs_mode = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", scripts.s = {max = 3, sequence = [{delay = 1}]}}
    })
    assert "script `max` only applies to `queued` or `parallel` mode" in _err, "got: ${_err}"
}

test_missing_required_keys_reported = lambda {
    _err = runtime.catch(lambda {
        Package {
            name = "p"
            automations.a = {
                triggers = [{trigger = "state"}]
                conditions = [{condition = "state", entity_id = "a.b"}]
                actions = [{choose = [{conditions = []}]}, {$if = []}, {repeat = {count = 1}}]
            }
        }
    })
    assert "automations.a.triggers[0]: state trigger is missing required keys [entity_id]" in _err, "got: ${_err}"
    assert "automations.a.conditions[0]: state condition is missing required keys [state]" in _err, "got: ${_err}"
    assert "automations.a.actions[0]: choose option needs `sequence`" in _err, "got: ${_err}"
    assert "automations.a.actions[1]: if action is missing required keys [then]" in _err, "got: ${_err}"
    assert "automations.a.actions[2]: repeat needs `sequence`" in _err, "got: ${_err}"
}

test_nested_errors_do_not_mask_later_errors = lambda {
    _err = runtime.catch(lambda {
        Package {
            name = "p"
            automations.a = {
                triggers = [{trigger = "motion.detected", target.entity_idd = "a.b"}, {trigger = "motion.detected", target.entity_id = "A.b"}]
                conditions = [{condition = "light.is_on", target.entity_idd = "a.b"}]
                actions = [{choose = [{conditions = [], sequence = [], bogus = 1}]}, {dleay = 1}]
            }
        }
    })
    assert "automations.a.triggers[0]: No attribute named 'entity_idd' in the schema 'Target'" in _err, "got: ${_err}"
    assert "automations.a.triggers[1]: target `entity_id` must be entity ids" in _err, "got: ${_err}"
    assert "automations.a.conditions[0]: No attribute named 'entity_idd' in the schema 'Target'" in _err, "got: ${_err}"
    assert "automations.a.actions[0]: No attribute named 'bogus' in the schema 'ChooseOption'" in _err, "got: ${_err}"
    assert "automations.a.actions[1]: unrecognised action with keys [dleay]" in _err, "got: ${_err}"
}

test_home_assistant_valid = lambda {
    _hall = Package {name = "hall"}
    _ha = HomeAssistant {packages = {_p.name: _p for _p in [_hall]}, integrations.logger.default = "warning", secrets.home_latitude = 40.7}
    assert _ha.packagesDir == "packages"
}

test_home_assistant_package_key_matches_name = lambda {
    _err = runtime.catch(lambda {
        HomeAssistant {packages.other = Package {name = "hall"}}
    })
    assert "each `packages` key must equal its Package name, got [other]" in _err, "got: ${_err}"
}

test_home_assistant_reserved_integration = lambda {
    _err = runtime.catch(lambda {
        HomeAssistant {integrations = {"template extra" = []}}
    })
    assert "integrations must not set [template extra]" in _err, "got: ${_err}"
}

test_home_assistant_secret_names = lambda {
    _err = runtime.catch(lambda {
        HomeAssistant {secrets = {"Home-Lat" = 1.0}}
    })
    assert "secret names must match [a-z0-9_]+, got [Home-Lat]" in _err, "got: ${_err}"
}

test_template_entity_conditions_validated = lambda {
    _err = runtime.catch(lambda {
        Package {name = "p", templates.t = {triggers = [{trigger = "time_pattern", minutes = "/5"}], sensors.s = {state = "1", conditions = [{condition = "state", entity_id = "a.b"}]}}}
    })
    assert "templates.t.sensors.s.conditions[0]: state condition is missing required keys [state]" in _err, "got: ${_err}"
}

test_get_entity_id_after_overlay_deletion = lambda {
    _p = Package {name = "hall", timers.hall_light = {}}
    _q = _p | {timers.hall_light = Undefined}
    _err = runtime.catch(lambda {
        _q.getEntityId("timer", "hall_light")
    })
    assert "package `hall` has no `timer` entry `hall_light`" in _err, "got: ${_err}"
}
