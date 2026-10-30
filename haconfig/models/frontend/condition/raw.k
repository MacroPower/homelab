schema RawCondition(ConditionBase):
    """RawCondition is the escape hatch for conditions that haconfig does not
    model, such as `device` or a custom integration's condition. `coerce` never
    builds it from a dict literal, so a typo cannot land in it. Write
    `condition.RawCondition {...}` explicitly. Every extra key is emitted as
    written.

    Examples
    --------
    condition.RawCondition {condition = "device", device_id = "abc", domain = "light", type = "is_on"}
    """
    [str]: any
