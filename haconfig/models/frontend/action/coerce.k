import models.frontend.condition

# HA picks an action's type from the first key present, in the order of
# `ACTIONS_MAP` in `homeassistant/helpers/config_validation.py`. `coerce`
# checks the keys in the same order. trigger/coerce.k explains why action
# lists are not typed with a union of schemas.
#
# The parameter and the locals of `coerce` carry the `_ac` prefix. Inside a
# lambda's comprehension, KCL resolves a name to a same-named attribute of the
# calling schema first.

# KEYS lists the action keys in `ACTIONS_MAP` order.
KEYS: [str] = ["action", "delay", "wait_template", "wait_for_trigger", "condition", "choose", "if", "repeat", "parallel", "sequence", "variables", "stop", "event"]

# _CTORS must be typed. An untyped map of lambdas fails to compile.
_CTORS: {str:(any) -> any} = {
    action = lambda _acA: any -> any { ServiceAction {**_acA} }
    delay = lambda _acA: any -> any { DelayAction {**_acA} }
    wait_template = lambda _acA: any -> any { WaitTemplateAction {**_acA} }
    wait_for_trigger = lambda _acA: any -> any { WaitForTriggerAction {**_acA} }
    condition = lambda _acA: any -> any { condition.coerce(_acA) }
    choose = lambda _acA: any -> any { ChooseAction {**_acA} }
    "if" = lambda _acA: any -> any { IfAction {**_acA} }
    repeat = lambda _acA: any -> any { RepeatAction {**_acA} }
    parallel = lambda _acA: any -> any { ParallelAction {**_acA} }
    sequence = lambda _acA: any -> any { SequenceAction {**_acA} }
    variables = lambda _acA: any -> any { VariablesAction {**_acA} }
    stop = lambda _acA: any -> any { StopAction {**_acA} }
    event = lambda _acA: any -> any { EventAction {**_acA} }
}

# _REQUIRED lists the required keys of each action besides its own key.
# `coerce` checks them by name, because KCL skips the required-attribute check
# of a schema built inside `runtime.catch` in a schema body, which is where
# Package validates its lists.
_REQUIRED: {str:[str]} = {
    "if" = ["then"]
}

# SCHEMAS lists every schema that an action list accepts, including every
# condition schema.
SCHEMAS: [str] = ["ServiceAction", "DelayAction", "WaitTemplateAction", "WaitForTriggerAction", "ChooseAction", "IfAction", "RepeatAction", "ParallelAction", "SequenceAction", "VariablesAction", "StopAction", "EventAction", "RawAction"] + condition.SCHEMAS

_PRIMITIVES = ["str", "int", "float", "bool", "list", "None", "Undefined"]

coerce = lambda _acIn: any -> any {
    """
    `coerce` validates one action and returns a schema instance. It builds a
    dict literal into the schema of the first `KEYS` entry present, and routes
    a `condition` key to `condition.coerce`. It passes an action or condition
    schema instance through unchanged, and fails on every other value. It never
    calls `runtime.catch`.
    """
    _acType = typeof(_acIn)
    _acIsDict = _acType == "dict"
    assert _acIsDict or _acType not in _PRIMITIVES, "an action must be a mapping, got ${_acType} `${_acIn}` (a bare list is only valid as a `parallel` branch)"
    assert _acIsDict or _acType in SCHEMAS, "a ${_acType} is not an action"
    assert not _acIsDict or "service" not in _acIn, "use `action:` instead of the legacy `service:` key"
    _acKeys = [_acK for _acK in KEYS if _acIsDict and _acK in _acIn]
    assert not _acIsDict or _acKeys, "unrecognised action with keys ${[_acK for _acK in _acIn]}; expected one of ${KEYS}, or action.RawAction {...}"
    _acKind = _acKeys[0] if _acKeys else ""
    _acMissing = [_acR for _acR in _REQUIRED[_acKind] if _acR not in _acIn] if _acKind in _REQUIRED else []
    assert not _acMissing, "${_acKind} action is missing required keys ${_acMissing}"
    _acIn if not _acIsDict else _CTORS[_acKind](_acIn)
}
