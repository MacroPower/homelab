# `coerce` dispatches a dict literal on its `trigger` value, which is the key HA
# itself dispatches on. Trigger lists are not typed with a union of schemas,
# because KCL chooses a union member for a dict literal by attribute names
# only. It takes the first member whose names fit and then fails on the
# literal value, so `SunTrigger` and `HomeAssistantTrigger`, which both have
# `trigger` and `event`, cannot share one union.
#
# The parameter and the locals of `coerce` carry the `_tc` prefix. Inside a
# lambda's comprehension, KCL resolves a name to a same-named attribute of the
# calling schema first.

# _CTORS must be typed. An untyped map of lambdas fails to compile.
_CTORS: {str:(any) -> any} = {
    state = lambda _tcT: any -> any { StateTrigger {**_tcT} }
    numeric_state = lambda _tcT: any -> any { NumericStateTrigger {**_tcT} }
    time = lambda _tcT: any -> any { TimeTrigger {**_tcT} }
    time_pattern = lambda _tcT: any -> any { TimePatternTrigger {**_tcT} }
    sun = lambda _tcT: any -> any { SunTrigger {**_tcT} }
    event = lambda _tcT: any -> any { EventTrigger {**_tcT} }
    homeassistant = lambda _tcT: any -> any { HomeAssistantTrigger {**_tcT} }
    template = lambda _tcT: any -> any { TemplateTrigger {**_tcT} }
    mqtt = lambda _tcT: any -> any { MqttTrigger {**_tcT} }
    webhook = lambda _tcT: any -> any { WebhookTrigger {**_tcT} }
    zone = lambda _tcT: any -> any { ZoneTrigger {**_tcT} }
}

# _REQUIRED lists the required keys of each classic trigger. `coerce` checks
# them by name, because KCL skips the required-attribute check of a schema
# built inside `runtime.catch` in a schema body, which is where Package
# validates its lists.
_REQUIRED: {str:[str]} = {
    state = ["entity_id"]
    numeric_state = ["entity_id"]
    time = ["at"]
    sun = ["event"]
    event = ["event_type"]
    homeassistant = ["event"]
    template = ["value_template"]
    mqtt = ["topic"]
    webhook = ["webhook_id"]
    zone = ["entity_id", "zone"]
}

# SCHEMAS lists every trigger schema, so other families can reject a trigger
# instance by name.
SCHEMAS: [str] = ["StateTrigger", "NumericStateTrigger", "TimeTrigger", "TimePatternTrigger", "SunTrigger", "EventTrigger", "HomeAssistantTrigger", "TemplateTrigger", "MqttTrigger", "WebhookTrigger", "ZoneTrigger", "PurposeTrigger", "RawTrigger"]

_PRIMITIVES = ["str", "int", "float", "bool", "list", "None", "Undefined"]

coerce = lambda _tcIn: any -> any {
    """
    `coerce` validates one trigger and returns a schema instance. It builds a
    dict literal into the classic schema that its `trigger` names, or into
    `PurposeTrigger` when the name contains `.`. It passes a trigger schema
    instance through unchanged, and fails on every other value. It never calls
    `runtime.catch`.
    """
    _tcType = typeof(_tcIn)
    _tcIsDict = _tcType == "dict"
    assert _tcIsDict or _tcType not in _PRIMITIVES, "a trigger must be a mapping, got ${_tcType} `${_tcIn}`"
    assert _tcIsDict or _tcType in SCHEMAS, "a ${_tcType} is not a trigger"
    assert not _tcIsDict or "platform" not in _tcIn, "use `trigger:` instead of the legacy `platform:` key"
    assert not _tcIsDict or "trigger" in _tcIn, "trigger needs a `trigger:` key, got keys ${[_tcK for _tcK in _tcIn]}"
    _tcKind = _tcIn.trigger if _tcIsDict else ""
    assert not _tcIsDict or _tcKind in _CTORS or "." in _tcKind, "unknown trigger `${_tcKind}`; use trigger.RawTrigger {...} for unmodelled platforms"
    _tcMissing = [_tcR for _tcR in _REQUIRED[_tcKind] if _tcR not in _tcIn] if _tcKind in _REQUIRED else []
    assert not _tcMissing, "${_tcKind} trigger is missing required keys ${_tcMissing}"
    _tcIn if not _tcIsDict else (_CTORS[_tcKind](_tcIn) if _tcKind in _CTORS else PurposeTrigger {**_tcIn})
}
