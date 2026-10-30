import runtime

test_valid_helpers = lambda {
    _helpers = [
        InputBoolean {name = "Override", icon = "mdi:lightbulb", initial = False}
        InputButton {name = "Doorbell"}
        InputNumber {min = 0.0, max = 10.0, initial = 10.0, step = 0.5, mode = "box"}
        InputSelect {options = ["a", "b"], initial = "b"}
        InputText {min = 0, max = 255, mode = "password"}
        InputDatetime {has_time = True}
        Timer {duration = {minutes = 5}, restore = True}
        Counter {initial = 0, step = 0, minimum = 0, maximum = 0}
    ]
    assert len(_helpers) == 8
}

test_icon_needs_prefix = lambda {
    _err = runtime.catch(lambda {
        _i: any = "lightbulb"
        InputBoolean {icon = _i}
    })
    assert "icon must look like `mdi:name`, got `lightbulb`" in _err, "got: ${_err}"
}

test_input_number_checks = lambda {
    _range = runtime.catch(lambda {
        _m: any = 10.0
        InputNumber {min = _m, max = 10.0}
    })
    _initial = runtime.catch(lambda {
        _i: any = 11.0
        InputNumber {min = 0.0, max = 10.0, initial = _i}
    })
    _step = runtime.catch(lambda {
        _s: any = 0.0
        InputNumber {min = 0.0, max = 10.0, step = _s}
    })
    assert "input_number `min` must be less than `max`" in _range, "got: ${_range}"
    assert "input_number `initial` must lie between `min` and `max`" in _initial, "got: ${_initial}"
    assert "input_number `step` must be more than 0" in _step, "got: ${_step}"
}

test_input_select_checks = lambda {
    _empty = runtime.catch(lambda {
        _o: any = []
        InputSelect {options = _o}
    })
    _dup = runtime.catch(lambda {
        _o: any = ["a", "a"]
        InputSelect {options = _o}
    })
    _initial = runtime.catch(lambda {
        _i: any = "c"
        InputSelect {options = ["a", "b"], initial = _i}
    })
    assert "input_select needs at least one option" in _empty, "got: ${_empty}"
    assert "input_select options must be unique" in _dup, "got: ${_dup}"
    assert "input_select `initial` must be one of `options`" in _initial, "got: ${_initial}"
}

test_input_text_checks = lambda {
    _min = runtime.catch(lambda {
        _m: any = 256
        InputText {min = _m}
    })
    _max = runtime.catch(lambda {
        _m: any = 0
        InputText {max = _m}
    })
    assert "input_text `min` must be between 0 and 255, inclusive" in _min, "got: ${_min}"
    assert "input_text `max` must be between 1 and 255, inclusive" in _max, "got: ${_max}"
}

test_input_datetime_needs_date_or_time = lambda {
    _err = runtime.catch(lambda {
        _d: any = False
        InputDatetime {has_date = _d}
    })
    assert "input_datetime needs `has_date` or `has_time`" in _err, "got: ${_err}"
}

test_counter_checks = lambda {
    _step = runtime.catch(lambda {
        _s: any = -1
        Counter {step = _s}
    })
    _bounds = runtime.catch(lambda {
        _m: any = 5
        Counter {minimum = _m, maximum = 1}
    })
    assert "counter `step` must be at least 0" in _step, "got: ${_step}"
    assert "counter `minimum` must not exceed `maximum`" in _bounds, "got: ${_bounds}"
}

test_schedule_block_checks = lambda {
    _ok = ScheduleBlock {from = "17:00", to = "24:00:00", data.mode = "comfort"}
    _from = runtime.catch(lambda {
        _f: any = "6:00"
        ScheduleBlock {from = _f, to = "08:00:00"}
    })
    _to = runtime.catch(lambda {
        _t: any = "25:00:00"
        ScheduleBlock {from = "06:00:00", to = _t}
    })
    _order = runtime.catch(lambda {
        _t: any = "05:00:00"
        ScheduleBlock {from = "06:00:00", to = _t}
    })
    assert "schedule `from` must be HH:MM[:SS], got `6:00`" in _from, "got: ${_from}"
    assert "schedule `to` must be HH:MM[:SS] or 24:00:00, got `25:00:00`" in _to, "got: ${_to}"
    assert "schedule block `from` must be before `to`" in _order, "got: ${_order}"
}

test_schedule_overlap_rejected = lambda {
    _ok = Schedule {name = "Heat", monday = [{from = "17:00:00", to = "24:00:00"}, {from = "06:00:00", to = "08:00:00"}]}
    _touching = Schedule {name = "Heat", friday = [{from = "06:00:00", to = "08:00:00"}, {from = "08:00:00", to = "09:00:00"}]}
    _err = runtime.catch(lambda {
        _b: any = [{from = "06:00:00", to = "09:00:00"}, {from = "08:00:00", to = "10:00:00"}]
        Schedule {name = "Heat", tuesday = _b}
    })
    assert "schedule blocks on one day must not overlap" in _err, "got: ${_err}"
}

test_schedule_icon_needs_prefix = lambda {
    _err = runtime.catch(lambda {
        _i: any = "calendar"
        Schedule {name = "Heat", icon = _i}
    })
    assert "icon must look like `mdi:name`" in _err, "got: ${_err}"
}

test_timer_duration_checked = lambda {
    _err = runtime.catch(lambda {
        Timer {duration = "5 minutes"}
    })
    assert "timer `duration` must be HH:MM[:SS]" in _err, "got: ${_err}"
}
