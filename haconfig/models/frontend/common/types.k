import regex

# The aliases below contain no schemas, so KCL coerces values into them
# without the union dispatch problem described in trigger/coerce.k.

# EntityIds is one entity id or a list of them.
type EntityIds = str | [str]
# Duration is `HH:MM[:SS]`, a number of seconds, or a mapping such as `{minutes = 5}`.
type Duration = str | int | float | {str:int | float | str}
# Template is a Jinja template string.
type Template = str
# Weekday is one of the day names that HA's time trigger and time condition
# accept.
type Weekday = "mon" | "tue" | "wed" | "thu" | "fri" | "sat" | "sun"

# TIME_OF_DAY matches a time of day, `HH:MM` or `HH:MM:SS`, from 00:00 to
# 23:59:59, inclusive.
TIME_OF_DAY = r"^([01]?\d|2[0-3]):[0-5]\d(:[0-5]\d)?$"

# DURATION_STR matches the duration strings that HA's `cv.time_period`
# accepts: `[-]HH:MM[:SS[.F]]`, or a number of seconds.
DURATION_STR = r"^[-+]?(\d+:\d+(:\d+(\.\d+)?)?|\d+(\.\d+)?)$"

# UUID matches an entity registry id, which HA accepts in place of an entity
# id in triggers, conditions, and targets.
UUID = r"^[0-9a-f]{32}$"

# SLUG matches the strings that HA's `slugify` leaves unchanged: lowercase
# `[a-z0-9_]`, with no leading, trailing, or double `_`.
SLUG = r"^[a-z0-9]+(_[a-z0-9]+)*$"

# ENTITY_ID is HA's `VALID_ENTITY_ID` from `homeassistant/core.py`, which
# matches `<domain>.<object_id>`.
ENTITY_ID = r"^(?!.+__)(?!_)[\da-z_]+(?<!_)\.(?!_)[\da-z_]+(?<!_)$"

isSlug = lambda s: str -> bool {
    """
    `isSlug` reports whether `s` matches `SLUG`, so HA uses it as an object id
    unchanged.
    """
    bool(regex.match(s, SLUG))
}

slugify = lambda s: str -> str {
    """
    `slugify` approximates HA's `slugify` for ASCII input. It lowercases `s`
    and turns every run of other characters into one `_`.
    """
    regex.replace(s.lower(), r"[^a-z0-9]+", "_").strip("_")
}

humanize = lambda key: str -> str {
    """
    `humanize` turns a slug key into a display name, so `motion_light` becomes
    `Motion light`.
    """
    key.replace("_", " ").capitalize()
}

asList = lambda v: any -> [any] {
    """
    `asList` returns `v` when it is a list, and `[v]` otherwise.
    """
    v if typeof(v) == "list" else [v]
}

isEntityIds = lambda v: any -> bool {
    """
    `isEntityIds` reports whether `v` is an entity id, an entity registry id,
    `all`, `none`, a template, or a list of those.
    """
    _eiList = asList(v)
    all _eiX in _eiList { typeof(_eiX) == "str" and (_eiX in ["all", "none"] or "{{" in _eiX or bool(regex.match(_eiX, ENTITY_ID)) or bool(regex.match(_eiX, UUID))) }
}

isDuration = lambda v: any -> bool {
    """
    `isDuration` reports whether `v` is a duration that HA accepts: a number,
    a mapping, a template, or a string that matches `DURATION_STR`. An
    Undefined `v` passes, so a schema can check an optional field directly.
    """
    v is Undefined or typeof(v) != "str" or "{{" in v or bool(regex.match(v, DURATION_STR))
}
