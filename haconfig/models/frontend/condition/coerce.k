# `coerce` dispatches a dict literal on its `condition` value. The `and`, `or`,
# and `not` conditions all have `condition` and `conditions`, so a union of
# schemas cannot tell them apart. trigger/coerce.k explains the union rule.
#
# The parameter and the locals of `coerce` carry the `_cc` prefix. Inside a
# lambda's comprehension, KCL resolves a name to a same-named attribute of the
# calling schema first.

# _CTORS must be typed. An untyped map of lambdas fails to compile.
_CTORS: {str:(any) -> any} = {
    "and" = lambda _ccC: any -> any { LogicCondition {**_ccC} }
    "or" = lambda _ccC: any -> any { LogicCondition {**_ccC} }
    "not" = lambda _ccC: any -> any { LogicCondition {**_ccC} }
    state = lambda _ccC: any -> any { StateCondition {**_ccC} }
    numeric_state = lambda _ccC: any -> any { NumericStateCondition {**_ccC} }
    template = lambda _ccC: any -> any { TemplateCondition {**_ccC} }
    time = lambda _ccC: any -> any { TimeCondition {**_ccC} }
    trigger = lambda _ccC: any -> any { TriggerCondition {**_ccC} }
    sun = lambda _ccC: any -> any { SunCondition {**_ccC} }
    zone = lambda _ccC: any -> any { ZoneCondition {**_ccC} }
}

# _REQUIRED lists the required keys of each classic condition. `coerce` checks
# them by name, because KCL skips the required-attribute check of a schema
# built inside `runtime.catch` in a schema body, which is where Package
# validates its lists.
_REQUIRED: {str:[str]} = {
    "and" = ["conditions"]
    "or" = ["conditions"]
    "not" = ["conditions"]
    state = ["entity_id", "state"]
    numeric_state = ["entity_id"]
    template = ["value_template"]
    trigger = ["id"]
    zone = ["entity_id", "zone"]
}

# SCHEMAS lists every condition schema, so other families can accept or reject
# a condition instance by name.
SCHEMAS: [str] = ["LogicCondition", "StateCondition", "NumericStateCondition", "TemplateCondition", "TimeCondition", "TriggerCondition", "SunCondition", "ZoneCondition", "PurposeCondition", "RawCondition"]

_PRIMITIVES = ["int", "float", "bool", "list", "None", "Undefined"]

coerce = lambda _ccIn: any -> any {
    """
    `coerce` validates one condition and returns a schema instance or a
    template string. It builds a dict literal into the classic schema that its
    `condition` names, or into `PurposeCondition` when the name contains `.`.
    It passes a template string and a condition schema instance through
    unchanged, and fails on every other value. It never calls `runtime.catch`.
    """
    _ccType = typeof(_ccIn)
    _ccIsDict = _ccType == "dict"
    assert _ccIsDict or _ccType not in _PRIMITIVES, "a condition must be a mapping or a template string, got ${_ccType} `${_ccIn}`"
    assert _ccIsDict or _ccType == "str" or _ccType in SCHEMAS, "a ${_ccType} is not a condition"
    assert _ccIsDict or _ccType != "str" or "{{" in _ccIn or "{%" in _ccIn, "a string condition must be a template, got `${_ccIn}`"
    assert not _ccIsDict or "condition" in _ccIn, "condition needs a `condition:` key (write `condition: and` rather than the `and:` shorthand), got keys ${[_ccK for _ccK in _ccIn]}"
    _ccKind = _ccIn.condition if _ccIsDict else ""
    assert not _ccIsDict or _ccKind in _CTORS or "." in _ccKind, "unknown condition `${_ccKind}`; use condition.RawCondition {...} for unmodelled conditions"
    _ccMissing = [_ccR for _ccR in _REQUIRED[_ccKind] if _ccR not in _ccIn] if _ccKind in _REQUIRED else []
    assert not _ccMissing, "${_ccKind} condition is missing required keys ${_ccMissing}"
    _ccIn if not _ccIsDict else (_CTORS[_ccKind](_ccIn) if _ccKind in _CTORS else PurposeCondition {**_ccIn})
}
