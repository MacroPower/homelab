schema Automation:
    """Automation runs `actions` when one of `triggers` fires and every entry of
    `conditions` passes. `Package` validates the three lists, so each error
    names its key path. The attribute order is the output order.
    More info: https://www.home-assistant.io/docs/automation/yaml/

    Attributes
    ----------
    id: str, default is "<package>.<key>", optional.
        Id is the automation's unique id, which keys its traces and its
        registry entry. The AutomationMixin derives it from the package name
        and the map key, so renaming `alias` keeps both. Set it only to adopt
        the id of an existing automation, or to keep an id across a key rename.
    alias: str, default is the humanized key, optional.
        Alias is the display name. HA derives the entity id from it when it
        first registers the automation, so the key `motion_light` gives the
        alias "Motion light" and the entity id `automation.motion_light`.
    description: str, default is Undefined, optional.
        Description is shown in the UI.
    initial_state: bool, default is Undefined, optional.
        InitialState forces the on or off state at startup instead of restoring
        the last state.
    mode: "single" | "restart" | "queued" | "parallel", default is Undefined, optional.
        Mode controls what happens when a trigger fires during a run. HA
        defaults to `single`.
    max: int, default is Undefined, optional.
        Max is the limit on concurrent or queued runs, at least 2. It applies
        only to `queued` and `parallel` mode.
    max_exceeded: str, default is Undefined, optional.
        MaxExceeded is the log level for a run that `max` blocks, or `silent`.
    trace: {str:int}, default is Undefined, optional.
        Trace sets `stored_traces`, the number of traces HA keeps.
    variables: {str:any}, default is Undefined, optional.
        Variables are evaluated after a trigger fires.
    trigger_variables: {str:any}, default is Undefined, optional.
        TriggerVariables are limited templates evaluated when the triggers
        attach.
    triggers: [any], default is Undefined, required.
        Triggers lists at least one trigger. Each entry passes `trigger.coerce`.
    conditions: [any], default is Undefined, optional.
        Conditions lists the conditions. Each entry passes `condition.coerce`.
    actions: [any], default is Undefined, required.
        Actions lists the actions. Each entry passes `action.coerce`.

    Examples
    --------
    automations.motion_light = {
        alias = "Hallway motion light"
        triggers = [{trigger = "motion.detected", target.entity_id = "binary_sensor.hallway_motion"}]
        actions = [{action = "light.turn_on", target.entity_id = "light.hallway"}]
    }
    """
    id?: str
    alias?: str
    description?: str
    initial_state?: bool
    mode?: "single" | "restart" | "queued" | "parallel"
    max?: int
    max_exceeded?: str
    trace?: {str:int}
    variables?: {str:any}
    trigger_variables?: {str:any}
    triggers: [any]
    conditions?: [any]
    actions: [any]

    check:
        triggers is Undefined or len(triggers) > 0, "automation needs at least one trigger"
        max is Undefined or mode in ["queued", "parallel"], "automation `max` only applies to `queued` or `parallel` mode"
        max is Undefined or max >= 2, "automation `max` must be at least 2"
