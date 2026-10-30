schema ScriptField:
    """ScriptField describes one input of a script, for the UI and for Assist.
    More info: https://www.home-assistant.io/integrations/script/#fields

    Attributes
    ----------
    name: str, default is Undefined, optional.
        Name is the field's display name.
    description: str, default is Undefined, optional.
        Description explains the field.
    example: any, default is Undefined, optional.
        Example is a sample value shown in the UI.
    default: any, default is Undefined, optional.
        Default is the value the UI fills in.
    required: bool, default is Undefined, optional.
        Required marks the field as mandatory in the UI.
    advanced: bool, default is Undefined, optional.
        Advanced hides the field unless the user enables advanced mode.
    selector: {str:any}, default is Undefined, optional.
        Selector picks the UI control, such as `{number = {min = 1, max = 100}}`.
        A selector without options, such as `{boolean = {}}`, renders as
        `boolean: null`, because HA's package merge drops an empty mapping.
    """
    name?: str
    description?: str
    example?: any
    default?: any
    required?: bool
    advanced?: bool
    selector?: {str:any}

schema Script:
    """Script is a reusable sequence of actions, exposed as `script.<key>`.
    `Package` validates `sequence`, so each error names its key path.
    More info: https://www.home-assistant.io/integrations/script/

    Attributes
    ----------
    alias: str, default is Undefined, optional.
        Alias is the display name. HA defaults it to the key.
    description: str, default is Undefined, optional.
        Description is shown in the UI and to Assist.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:lightbulb`.
    mode: "single" | "restart" | "queued" | "parallel", default is Undefined, optional.
        Mode controls what happens when the script starts during a run. HA
        defaults to `single`.
    max: int, default is Undefined, optional.
        Max is the limit on concurrent or queued runs. It applies only to
        `queued` and `parallel` mode.
    max_exceeded: str, default is Undefined, optional.
        MaxExceeded is the log level for a run that `max` blocks, or `silent`.
    trace: {str:int}, default is Undefined, optional.
        Trace sets `stored_traces`, the number of traces HA keeps.
    variables: {str:any}, default is Undefined, optional.
        Variables are evaluated when the script starts.
    fields: {str:ScriptField}, default is Undefined, optional.
        Fields declares the script's inputs, keyed by variable name.
    sequence: [any], default is Undefined, required.
        Sequence lists the actions. Each entry passes `action.coerce`.

    Examples
    --------
    scripts.hallway_light_on = {
        mode = "restart"
        sequence = [{action = "light.turn_on", target.entity_id = "light.hallway"}]
    }
    """
    alias?: str
    description?: str
    icon?: str
    mode?: "single" | "restart" | "queued" | "parallel"
    max?: int
    max_exceeded?: str
    trace?: {str:int}
    variables?: {str:any}
    fields?: {str:ScriptField}
    sequence: [any]

    check:
        icon is Undefined or ":" in icon, "icon must look like `mdi:name`, got `${icon}`"
        max is Undefined or mode in ["queued", "parallel"], "script `max` only applies to `queued` or `parallel` mode"
