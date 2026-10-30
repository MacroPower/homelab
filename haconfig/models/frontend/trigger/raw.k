schema RawTrigger(TriggerBase):
    """RawTrigger is the escape hatch for trigger platforms that haconfig does not
    model, such as `tag`, `calendar`, `device`, `conversation`, or a custom
    integration's trigger. `coerce` never builds it from a dict literal, so a
    typo cannot land in it. Write `trigger.RawTrigger {...}` explicitly. Every
    extra key is emitted as written.

    Examples
    --------
    trigger.RawTrigger {trigger = "tag", tag_id = "front_door"}
    """
    [str]: any
