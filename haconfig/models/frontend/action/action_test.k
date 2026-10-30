import runtime

import models.frontend.trigger

test_every_action_kind_dispatches = lambda {
    _cases = {
        ServiceAction = {action = "light.turn_on", target.entity_id = "light.x"}
        DelayAction = {delay = {minutes = 5}}
        WaitTemplateAction = {wait_template = "{{ true }}"}
        WaitForTriggerAction = {wait_for_trigger = [{trigger = "state", entity_id = "a.b"}]}
        StateCondition = {condition = "state", entity_id = "a.b", state = "on"}
        ChooseAction = {choose = [{conditions = ["{{ true }}"], sequence = [{delay = 1}]}], default = [{delay = 2}]}
        IfAction = {$if = ["{{ true }}"], then = [{delay = 1}], $else = [{delay = 2}]}
        RepeatAction = {repeat = {count = 2, sequence = [{delay = 1}]}}
        ParallelAction = {parallel = [{sequence = [{delay = 1}]}, {delay = 2}]}
        SequenceAction = {sequence = [{delay = 1}]}
        VariablesAction = {variables = {x = 1}}
        StopAction = {stop = "done"}
        EventAction = {event = "my_event"}
    }
    _got = {_k = typeof(coerce(_v)) for _k, _v in _cases}
    assert all _k, _v in _got { _k == _v }, "got: ${_got}"
}

test_nested_typo_fails = lambda {
    _err = runtime.catch(lambda {
        _a: any = {$if = ["{{ true }}"], then = [{choose = [{conditions = [], sequence = [{dleay = 1}]}]}]}
        coerce(_a)
    })
    assert "unrecognised action with keys [dleay]" in _err, "got: ${_err}"
}

test_nested_trigger_typo_fails = lambda {
    _err = runtime.catch(lambda {
        _a: any = {wait_for_trigger = [{trigger = "state", entity_id = "a.b", too = "on"}]}
        coerce(_a)
    })
    assert "No attribute named 'too'" in _err, "got: ${_err}"
}

test_legacy_service_rejected = lambda {
    _err = runtime.catch(lambda {
        _a: any = {service = "light.turn_on"}
        coerce(_a)
    })
    assert "legacy `service:`" in _err, "got: ${_err}"
}

test_raw_passes_through = lambda {
    _a = RawAction {device_id = "abc", domain = "light", type = "turn_on"}
    assert typeof(coerce(_a)) == "RawAction"
}

test_wrong_family_instance_rejected = lambda {
    _err = runtime.catch(lambda {
        coerce(trigger.StateTrigger {entity_id = "a.b"})
    })
    assert "a StateTrigger is not an action" in _err, "got: ${_err}"
}

test_target_typo_and_template_data = lambda {
    _ok = coerce({action = "notify.mobile", data = "{{ {'message': 'hi'} }}", target = "{{ targets }}"})
    assert typeof(_ok) == "ServiceAction"
    _err = runtime.catch(lambda {
        _a: any = {action = "light.turn_on", target.entity_idd = "light.x"}
        coerce(_a)
    })
    assert "No attribute named 'entity_idd'" in _err, "got: ${_err}"
}

test_bad_entity_id_rejected = lambda {
    _err = runtime.catch(lambda {
        _a: any = {action = "light.turn_on", target.entity_id = "Light.Hallway"}
        coerce(_a)
    })
    assert "target `entity_id` must be entity ids" in _err, "got: ${_err}"
}

test_parallel_list_branch_validated = lambda {
    _ok = coerce({parallel = [[{delay = 1}, {delay = 2}], {delay = 3}]})
    assert typeof(_ok) == "ParallelAction"
    _err = runtime.catch(lambda {
        _a: any = {parallel = [[{delay = 1}, {dleay = 2}]]}
        coerce(_a)
    })
    assert "unrecognised action with keys [dleay]" in _err, "got: ${_err}"
}

test_bare_list_outside_parallel_rejected = lambda {
    _err = runtime.catch(lambda {
        _a: any = [{delay = 1}]
        coerce(_a)
    })
    assert "a bare list is only valid as a `parallel` branch" in _err, "got: ${_err}"
}

test_repeat_needs_one_mode = lambda {
    _err = runtime.catch(lambda {
        _a: any = {repeat = {count = 2, until = ["{{ true }}"], sequence = [{delay = 1}]}}
        coerce(_a)
    })
    assert "repeat needs exactly one of" in _err, "got: ${_err}"
}

test_stop_error_excludes_response_variable = lambda {
    _err = runtime.catch(lambda {
        _a: any = {stop = "x", error = True, response_variable = "r"}
        coerce(_a)
    })
    assert "stop `response_variable` is not allowed with `error: true`" in _err, "got: ${_err}"
}

test_service_action_without_target = lambda {
    _a = coerce({action = "homeassistant.restart"})
    assert typeof(_a) == "ServiceAction"
}

test_service_action_ui_fields_accepted = lambda {
    _a = coerce({action = "light.turn_on", entity_id = "light.a", metadata = {}})
    _b = coerce({action = "light.turn_on", target.entity_id = "0123456789abcdef0123456789abcdef"})
    assert typeof(_a) == "ServiceAction" and typeof(_b) == "ServiceAction"
}

test_delay_checked = lambda {
    _err = runtime.catch(lambda {
        coerce({delay = "5 minutes"})
    })
    assert "delay must be HH:MM[:SS]" in _err, "got: ${_err}"
}
