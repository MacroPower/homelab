schema TriggerBase:
    """TriggerBase holds the keys that every trigger accepts. Each trigger schema
    narrows `trigger` to its platform.
    More info: https://www.home-assistant.io/docs/automation/trigger/

    Attributes
    ----------
    trigger: str, default is Undefined, required.
        Trigger is the platform, such as `state` or `light.turned_on`.
    id: str, default is Undefined, optional.
        Id is the trigger id. Templates read it as `trigger.id`, and a
        `condition: trigger` matches it.
    alias: str, default is Undefined, optional.
        Alias is the trigger's display name.
    variables: {str:any}, default is Undefined, optional.
        Variables are evaluated when the trigger fires.
    enabled: bool | str, default is Undefined, optional.
        Enabled disables the trigger when false. A limited template is allowed.
    """
    trigger: str
    id?: str
    alias?: str
    variables?: {str:any}
    enabled?: bool | str
