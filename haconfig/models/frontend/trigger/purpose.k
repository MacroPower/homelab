import models.frontend.common

schema PurposeTrigger(TriggerBase):
    """PurposeTrigger is a purpose-specific trigger, such as `light.turned_on` or
    `motion.detected`. The name must be in `TRIGGERS`, the catalog generated
    from the pinned HA release, and every option key must be one that the
    catalog lists for the name. Option values are not typed.
    More info: https://www.home-assistant.io/docs/automation/trigger/

    Attributes
    ----------
    trigger: str, default is Undefined, required.
        Trigger is `<domain>.<name>`.
    target: any, default is Undefined, optional.
        Target is a `common.Target` mapping that selects the entities, devices,
        areas, floors, or labels to watch.
    options: {str:any}, default is Undefined, optional.
        Options are specific to the trigger, such as `behavior`, `for`, or
        `threshold`. `behavior` is `each`, `first`, or `all`.

    Examples
    --------
    {trigger = "motion.detected", target.entity_id = "binary_sensor.hallway_motion", options.behavior = "first"}
    """
    target?: any
    options?: {str:any}

    # A typed `target` reports a misspelled key only as "expect Target, got
    # dict", and inside Package validation its failure masks later errors, so
    # a mapping is built explicitly.
    _target?: any = common.Target {**target} if typeof(target) in ["dict", "Target"] else target

    _optionKeys: [str] = [_k for _k in options or {}]
    _known: [str] = TRIGGERS[trigger] if trigger in TRIGGERS else []
    _unknownOptions: [str] = [_k for _k in _optionKeys if _k not in _known]

    check:
        target is Undefined or typeof(target) in ["dict", "Target"], "trigger `target` must be a mapping, got `${target}`"
        trigger in TRIGGERS, "unknown trigger `${trigger}` (not in the Home Assistant ${HA_VERSION} catalog); use trigger.RawTrigger {...} for custom integrations"
        not _unknownOptions, "trigger `${trigger}` has unknown option(s) ${_unknownOptions}; known: ${_known}"
        not options?.behavior or options.behavior in ["each", "first", "all"], "trigger `behavior` must be `each`, `first` or `all` (`any` and `last` break in 2027.1), got `${options?.behavior}`"
