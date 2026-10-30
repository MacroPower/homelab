schema ActionBase:
    """ActionBase holds the keys that every action accepts.
    More info: https://www.home-assistant.io/docs/scripts/

    Attributes
    ----------
    alias: str, default is Undefined, optional.
        Alias is the step's display name in traces.
    enabled: bool | str, default is Undefined, optional.
        Enabled skips the step when false. A limited template is allowed.
    continue_on_error: bool, default is Undefined, optional.
        ContinueOnError keeps the sequence running when this step raises an
        error.
    """
    alias?: str
    enabled?: bool | str
    continue_on_error?: bool
