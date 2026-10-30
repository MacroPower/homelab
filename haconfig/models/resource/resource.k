schema DomainMapping:
    """DomainMapping maps an HA domain key, such as `automation`, `script`,
    `input_boolean`, or the labelled `automation raw`, to the list or mapping
    rendered under it. The backends place their output in a DomainMapping.
    """
    [str]: any
