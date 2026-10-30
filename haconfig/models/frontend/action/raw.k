schema RawAction(ActionBase):
    """RawAction is the escape hatch for actions that haconfig does not model,
    such as device actions or `scene`. `coerce` never builds it from a dict
    literal, so a typo cannot land in it. Write `action.RawAction {...}`
    explicitly. Every extra key is emitted as written.

    Examples
    --------
    action.RawAction {device_id = "abc", domain = "light", type = "turn_on"}
    """
    [str]: any
