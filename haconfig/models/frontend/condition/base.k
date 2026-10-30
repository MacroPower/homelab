schema ConditionBase:
    """ConditionBase holds the keys that every condition accepts. Each condition
    schema narrows `condition` to its kind.
    More info: https://www.home-assistant.io/docs/scripts/conditions/

    Attributes
    ----------
    condition: str, default is Undefined, required.
        Condition is the condition kind, such as `state` or `light.is_on`.
    alias: str, default is Undefined, optional.
        Alias is the condition's display name.
    enabled: bool | str, default is Undefined, optional.
        Enabled disables the condition when false. A limited template is allowed.
    """
    condition: str
    alias?: str
    enabled?: bool | str
