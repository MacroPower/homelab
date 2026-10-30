import regex

import models.frontend.common

schema HelperBase:
    """HelperBase holds the keys that every YAML helper accepts, except
    `Schedule`, which requires `name`. A helper's map key is its object id.

    Attributes
    ----------
    name: str, default is Undefined, optional.
        Name is the friendly name. HA falls back to the object id.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:lightbulb`.
    """
    name?: str
    icon?: str

    check:
        icon is Undefined or ":" in icon, "icon must look like `mdi:name`, got `${icon}`"

schema InputBoolean(HelperBase):
    """InputBoolean is a toggle helper, `input_boolean.<key>`.
    More info: https://www.home-assistant.io/integrations/input_boolean/

    Attributes
    ----------
    initial: bool, default is Undefined, optional.
        Initial is the state at startup. Without it, HA restores the last state.
    """
    initial?: bool

schema InputButton(HelperBase):
    """InputButton is a helper that the user can press, `input_button.<key>`.
    More info: https://www.home-assistant.io/integrations/input_button/
    """

schema InputNumber(HelperBase):
    """InputNumber is a numeric helper, `input_number.<key>`.
    More info: https://www.home-assistant.io/integrations/input_number/

    Attributes
    ----------
    min: float, default is Undefined, required.
        Min is the lowest value. It must be less than `max`.
    max: float, default is Undefined, required.
        Max is the highest value.
    initial: float, default is Undefined, optional.
        Initial is the value at startup, between `min` and `max`, inclusive.
    step: float, default is Undefined, optional.
        Step is the increment. It must be more than 0.
    mode: "slider" | "box", default is Undefined, optional.
        Mode selects the UI control. HA defaults to `slider`.
    unit_of_measurement: str, default is Undefined, optional.
        UnitOfMeasurement is the value's unit.
    """
    min: float
    max: float
    initial?: float
    step?: float
    mode?: "slider" | "box"
    unit_of_measurement?: str

    check:
        min is Undefined or max is Undefined or min < max, "input_number `min` must be less than `max`"
        initial is Undefined or min is Undefined or max is Undefined or min <= initial <= max, "input_number `initial` must lie between `min` and `max`"
        step is Undefined or step > 0, "input_number `step` must be more than 0"

schema InputSelect(HelperBase):
    """InputSelect is a dropdown helper, `input_select.<key>`.
    More info: https://www.home-assistant.io/integrations/input_select/

    Attributes
    ----------
    options: [str], default is Undefined, required.
        Options lists at least one option, with no duplicates.
    initial: str, default is Undefined, optional.
        Initial is the option selected at startup. It must be in `options`.
    """
    options: [str]
    initial?: str

    check:
        options is Undefined or len(options) > 0, "input_select needs at least one option"
        options is Undefined or isunique(options), "input_select options must be unique"
        initial is Undefined or initial in options, "input_select `initial` must be one of `options`"

schema InputText(HelperBase):
    """InputText is a text helper, `input_text.<key>`.
    More info: https://www.home-assistant.io/integrations/input_text/

    Attributes
    ----------
    min: int, default is Undefined, optional.
        Min is the shortest length, between 0 and 255, inclusive.
    max: int, default is Undefined, optional.
        Max is the longest length, between 1 and 255, inclusive.
    initial: str, default is Undefined, optional.
        Initial is the value at startup.
    pattern: str, default is Undefined, optional.
        Pattern is a regular expression that the UI validates input against.
    mode: "text" | "password", default is Undefined, optional.
        Mode selects the UI control. HA defaults to `text`.
    unit_of_measurement: str, default is Undefined, optional.
        UnitOfMeasurement is the value's unit.
    """
    min?: int
    max?: int
    initial?: str
    pattern?: str
    mode?: "text" | "password"
    unit_of_measurement?: str

    check:
        min is Undefined or 0 <= min <= 255, "input_text `min` must be between 0 and 255, inclusive"
        max is Undefined or 1 <= max <= 255, "input_text `max` must be between 1 and 255, inclusive"

schema InputDatetime(HelperBase):
    """InputDatetime is a date helper, a time helper, or both,
    `input_datetime.<key>`.
    More info: https://www.home-assistant.io/integrations/input_datetime/

    Attributes
    ----------
    has_date: bool, default is Undefined, optional.
        HasDate stores a date.
    has_time: bool, default is Undefined, optional.
        HasTime stores a time.
    initial: str, default is Undefined, optional.
        Initial is the value at startup, such as `2026-01-01 07:30:00`.
    """
    has_date?: bool
    has_time?: bool
    initial?: str

    check:
        has_date or has_time, "input_datetime needs `has_date` or `has_time`"

schema Timer(HelperBase):
    """Timer is a countdown helper, `timer.<key>`.
    More info: https://www.home-assistant.io/integrations/timer/

    Attributes
    ----------
    duration: str | int | {str:int | float}, default is Undefined, optional.
        Duration is the default run time. HA defaults to 0.
    restore: bool, default is Undefined, optional.
        Restore resumes an active or paused timer after a restart.
    """
    duration?: str | int | {str:int | float}
    restore?: bool

    check:
        common.isDuration(duration), "timer `duration` must be HH:MM[:SS], seconds or a mapping, got `${duration}`"

schema Counter(HelperBase):
    """Counter is an integer counter helper, `counter.<key>`.
    More info: https://www.home-assistant.io/integrations/counter/

    Attributes
    ----------
    initial: int, default is Undefined, optional.
        Initial is the value at startup and after a reset.
    step: int, default is Undefined, optional.
        Step is the increment, at least 0.
    minimum: int, default is Undefined, optional.
        Minimum is the lowest value. It must not exceed `maximum`.
    maximum: int, default is Undefined, optional.
        Maximum is the highest value.
    restore: bool, default is Undefined, optional.
        Restore keeps the value across restarts. HA defaults to true.
    """
    initial?: int
    step?: int
    minimum?: int
    maximum?: int
    restore?: bool

    check:
        step is Undefined or step >= 0, "counter `step` must be at least 0"
        minimum is Undefined or maximum is Undefined or minimum <= maximum, "counter `minimum` must not exceed `maximum`"

# _sec returns the seconds since midnight of `HH:MM[:SS]`. Its parameter and
# locals carry the `_sc` prefix, because a name inside a lambda's
# comprehension resolves to a same-named attribute of the calling schema first.
_sec = lambda _scTime: str -> int {
    _scParts = [int(_scP) for _scP in _scTime.split(":")]
    _scParts[0] * 3600 + _scParts[1] * 60 + (_scParts[2] if len(_scParts) > 2 else 0)
}

schema ScheduleBlock:
    """ScheduleBlock is one period of a schedule day, during which the schedule
    is on.

    Attributes
    ----------
    from: str, default is Undefined, required.
        From is the start time, `HH:MM[:SS]`.
    to: str, default is Undefined, required.
        To is the end time, `HH:MM[:SS]` or `24:00:00`. It must be after `from`.
    data: {str:bool | str | int | float}, default is Undefined, optional.
        Data is exposed as state attributes while the block is active.
    """
    from: str
    to: str
    data?: {str:bool | str | int | float}

    check:
        from is Undefined or regex.match(from, r"^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$"), "schedule `from` must be HH:MM[:SS], got `${from}`"
        to is Undefined or regex.match(to, r"^(([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?|24:00(:00)?)$"), "schedule `to` must be HH:MM[:SS] or 24:00:00, got `${to}`"
        from is Undefined or to is Undefined or _sec(from) < _sec(to), "schedule block `from` must be before `to`, got ${from}-${to}"

schema Schedule:
    """Schedule is a weekly schedule helper, `schedule.<key>`, which is on during
    its blocks. HA requires `name` on a schedule.
    More info: https://www.home-assistant.io/integrations/schedule/

    Attributes
    ----------
    name: str, default is Undefined, required.
        Name is the friendly name.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:calendar`.
    monday: [ScheduleBlock], default is Undefined, optional.
        Monday lists Monday's blocks. Blocks on one day must not overlap.
    tuesday: [ScheduleBlock], default is Undefined, optional.
        Tuesday lists Tuesday's blocks.
    wednesday: [ScheduleBlock], default is Undefined, optional.
        Wednesday lists Wednesday's blocks.
    thursday: [ScheduleBlock], default is Undefined, optional.
        Thursday lists Thursday's blocks.
    friday: [ScheduleBlock], default is Undefined, optional.
        Friday lists Friday's blocks.
    saturday: [ScheduleBlock], default is Undefined, optional.
        Saturday lists Saturday's blocks.
    sunday: [ScheduleBlock], default is Undefined, optional.
        Sunday lists Sunday's blocks.

    Examples
    --------
    schedules.heating = {
        name = "Heating"
        monday = [{from = "06:00:00", to = "08:00:00"}, {from = "17:00:00", to = "24:00:00"}]
    }
    """
    name: str
    icon?: str
    monday?: [ScheduleBlock]
    tuesday?: [ScheduleBlock]
    wednesday?: [ScheduleBlock]
    thursday?: [ScheduleBlock]
    friday?: [ScheduleBlock]
    saturday?: [ScheduleBlock]
    sunday?: [ScheduleBlock]

    # Blocks without `from` or `to` fail their own required-attribute check.
    _days: [[ScheduleBlock]] = [[_b for _b in _d if _b.from and _b.to] for _d in [monday, tuesday, wednesday, thursday, friday, saturday, sunday] if _d]
    # The blocks of a day are disjoint when, after sorting the starts and the
    # ends, each start is at or after the previous end.
    _overlaps: [bool] = [_sec(sorted([_b.from for _b in _d])[_i + 1]) < _sec(sorted([_b.to for _b in _d])[_i]) for _d in _days for _i in range(len(_d) - 1)]

    check:
        icon is Undefined or ":" in icon, "icon must look like `mdi:name`, got `${icon}`"
        not any _o in _overlaps { _o }, "schedule blocks on one day must not overlap"
