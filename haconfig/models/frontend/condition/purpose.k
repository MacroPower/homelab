import models.frontend.common

schema PurposeCondition(ConditionBase):
    """PurposeCondition is a purpose-specific condition, such as `light.is_on`.
    The name must be in `CONDITIONS`, the catalog generated from the pinned HA
    release, and every option key must be one that the catalog lists for the
    name. Option values are not typed.
    More info: https://www.home-assistant.io/docs/scripts/conditions/

    Attributes
    ----------
    condition: str, default is Undefined, required.
        Condition is `<domain>.<name>`.
    target: any, default is Undefined, optional.
        Target is a `common.Target` mapping that selects the entities, devices,
        areas, floors, or labels to test.
    options: {str:any}, default is Undefined, optional.
        Options are specific to the condition. `behavior` is `any` or `all`.

    Examples
    --------
    {condition = "light.is_on", target.entity_id = "light.hallway"}
    """
    target?: any
    options?: {str:any}

    # A typed `target` reports a misspelled key only as "expect Target, got
    # dict", and inside Package validation its failure masks later errors, so
    # a mapping is built explicitly.
    _target?: any = common.Target {**target} if typeof(target) in ["dict", "Target"] else target

    _optionKeys: [str] = [_k for _k in options or {}]
    _known: [str] = CONDITIONS[condition] if condition in CONDITIONS else []
    _unknownOptions: [str] = [_k for _k in _optionKeys if _k not in _known]

    check:
        target is Undefined or typeof(target) in ["dict", "Target"], "condition `target` must be a mapping, got `${target}`"
        condition in CONDITIONS, "unknown condition `${condition}` (not in the Home Assistant ${HA_VERSION} catalog); use condition.RawCondition {...} for custom integrations"
        not _unknownOptions, "condition `${condition}` has unknown option(s) ${_unknownOptions}; known: ${_known}"
        not options?.behavior or options.behavior in ["any", "all"], "condition `behavior` must be `any` or `all`, got `${options?.behavior}`"
