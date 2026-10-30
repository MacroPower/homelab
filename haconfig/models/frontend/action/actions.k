import models.frontend.common
import models.frontend.condition
import models.frontend.trigger

# Container actions validate their nested lists in private attributes. The
# encoder drops private attributes, so the output holds each list as the user
# wrote it. Nested schemas such as ChooseOption, Repeat, and Target are typed
# `any` and built explicitly in private attributes. Inside Package validation,
# a failure in a typed nested schema masks every later error. A typed nested
# schema also reports a misspelled key only as "expect ChooseOption, got dict".

schema ServiceAction(ActionBase):
    """ServiceAction performs an action, such as `light.turn_on`. HA called
    these service calls before 2024.8.
    More info: https://www.home-assistant.io/docs/scripts/perform-actions/

    Attributes
    ----------
    action: str, default is Undefined, required.
        Action is `<domain>.<action>`, or a template.
    target: any, default is Undefined, optional.
        Target is a `common.Target` mapping or a template. A mapping is built
        as `common.Target`, so a misspelled key fails with its name.
    entity_id: str | [str], default is Undefined, optional.
        EntityId is the target entity or entities, outside `target`. HA
        accepts it for older configs, and `target.entity_id` replaces it.
    data: {str:any} | str, default is Undefined, optional.
        Data is the action data, or a template that renders to a mapping.
    metadata: {str:any}, default is Undefined, optional.
        Metadata is the UI editor's bookkeeping. HA accepts and drops it.
    response_variable: str, default is Undefined, optional.
        ResponseVariable names the variable that stores the action's response.

    Examples
    --------
    {action = "light.turn_on", target.entity_id = "light.hallway", data.brightness_pct = 40}
    """
    action: str
    target?: any
    entity_id?: common.EntityIds
    data?: {str:any} | str
    metadata?: {str:any}
    response_variable?: str

    # A `Target | str` union reports a misspelled key only as "expect Target |
    # str, got dict", so a mapping is built explicitly.
    _target?: any = common.Target {**target} if typeof(target) in ["dict", "Target"] else target

    check:
        target is Undefined or typeof(target) in ["dict", "Target"] or (typeof(target) == "str" and "{{" in target), "action `target` must be a mapping or a template, got `${target}`"
        "." in action or "{{" in action, "action must be `<domain>.<action>` or a template, got `${action}`"
        entity_id is Undefined or common.isEntityIds(entity_id), "action `entity_id` must be entity ids, `all`, `none` or a template, got `${entity_id}`"

schema DelayAction(ActionBase):
    """DelayAction waits for a duration.
    More info: https://www.home-assistant.io/docs/scripts/#wait-for-time-to-pass-delay

    Attributes
    ----------
    delay: str | int | float | {str:}, default is Undefined, required.
        Delay is the duration, such as `00:01:30`, `90`, or `{minutes = 1}`.
    """
    delay: common.Duration

    check:
        common.isDuration(delay), "delay must be HH:MM[:SS], seconds, a mapping or a template, got `${delay}`"

schema WaitTemplateAction(ActionBase):
    """WaitTemplateAction waits until a template renders true.
    More info: https://www.home-assistant.io/docs/scripts/#wait-for-a-template

    Attributes
    ----------
    wait_template: str, default is Undefined, required.
        WaitTemplate is the template to wait for.
    timeout: str | int | float | {str:}, default is Undefined, optional.
        Timeout ends the wait after this duration.
    continue_on_timeout: bool, default is Undefined, optional.
        ContinueOnTimeout runs the rest of the sequence after a timeout. HA
        defaults to true.
    """
    wait_template: common.Template
    timeout?: common.Duration
    continue_on_timeout?: bool

    check:
        common.isDuration(timeout), "wait_template `timeout` must be HH:MM[:SS], seconds, a mapping or a template, got `${timeout}`"

schema WaitForTriggerAction(ActionBase):
    """WaitForTriggerAction waits until one of its triggers fires.
    More info: https://www.home-assistant.io/docs/scripts/#wait-for-a-trigger

    Attributes
    ----------
    wait_for_trigger: [any], default is Undefined, required.
        WaitForTrigger lists the triggers. Each entry passes `trigger.coerce`.
    timeout: str | int | float | {str:}, default is Undefined, optional.
        Timeout ends the wait after this duration.
    continue_on_timeout: bool, default is Undefined, optional.
        ContinueOnTimeout runs the rest of the sequence after a timeout. HA
        defaults to true.
    """
    wait_for_trigger: [any]
    timeout?: common.Duration
    continue_on_timeout?: bool

    _triggers: [any] = [trigger.coerce(_t) for _t in wait_for_trigger]

    check:
        common.isDuration(timeout), "wait_for_trigger `timeout` must be HH:MM[:SS], seconds, a mapping or a template, got `${timeout}`"

schema ChooseOption:
    """ChooseOption is one branch of a `choose` action.

    Attributes
    ----------
    alias: str, default is Undefined, optional.
        Alias is the branch's display name in traces.
    conditions: [any], default is Undefined, required.
        Conditions must all pass for the branch to run. Each entry passes
        `condition.coerce`.
    sequence: [any], default is Undefined, required.
        Sequence is the branch's actions. Each entry passes `coerce`.
    """
    alias?: str
    conditions: [any]
    sequence: [any]

    _conditions: [any] = [condition.coerce(_c) for _c in conditions or []]
    _sequence: [any] = [coerce(_a) for _a in sequence or []]

    # KCL skips the required-attribute check inside Package validation.
    check:
        conditions is not Undefined, "choose option needs `conditions`"
        sequence is not Undefined, "choose option needs `sequence`"

schema ChooseAction(ActionBase):
    """ChooseAction runs the first option whose conditions all pass, or the
    `default` actions when none does.
    More info: https://www.home-assistant.io/docs/scripts/#choose-a-group-of-actions

    Attributes
    ----------
    choose: [any], default is Undefined, required.
        Choose lists the options in the order HA tests them. Each entry is
        built as a ChooseOption.
    default: [any], default is Undefined, optional.
        Default runs when no option matches. Each entry passes `coerce`.
    """
    choose: [any]
    default?: [any]

    _choose: [any] = [ChooseOption {**_o} for _o in choose]
    _default: [any] = [coerce(_a) for _a in default or []]

schema IfAction(ActionBase):
    """IfAction runs `then` when every condition in `if` passes, and `else`
    otherwise. Write the keyword keys with a `$` prefix (`$if`, `$else`).
    More info: https://www.home-assistant.io/docs/scripts/#if-then

    Attributes
    ----------
    if: [any], default is Undefined, required.
        If lists the conditions. Each entry passes `condition.coerce`.
    then: [any], default is Undefined, required.
        Then lists the actions to run when the conditions pass.
    else: [any], default is Undefined, optional.
        Else lists the actions to run when a condition fails.
    """
    $if: [any]
    then: [any]
    $else?: [any]

    _if: [any] = [condition.coerce(_c) for _c in $if]
    _then: [any] = [coerce(_a) for _a in then]
    _else: [any] = [coerce(_a) for _a in $else or []]

schema Repeat:
    """Repeat is the body of a `repeat` action. It holds `sequence` and exactly
    one of `count`, `for_each`, `while`, and `until`.

    Attributes
    ----------
    sequence: [any], default is Undefined, required.
        Sequence is the repeated actions. Each entry passes `coerce`.
    count: int | str, default is Undefined, optional.
        Count is the number of runs, or a template.
    for_each: [any] | str, default is Undefined, optional.
        ForEach runs once per item, readable as `repeat.item`.
    while: [any], default is Undefined, optional.
        While repeats while every condition passes, testing before each run.
    until: [any], default is Undefined, optional.
        Until repeats until every condition passes, testing after each run.
    """
    sequence: [any]
    count?: int | str
    for_each?: [any] | str
    $while?: [any]
    until?: [any]

    _sequence: [any] = [coerce(_a) for _a in sequence or []]
    _conds: [any] = [condition.coerce(_c) for _c in ($while or []) + (until or [])]
    _modes: [any] = [_x for _x in [count, for_each, $while, until] if _x is not Undefined]

    # KCL skips the required-attribute check inside Package validation.
    check:
        sequence is not Undefined, "repeat needs `sequence`"
        len(_modes) == 1, "repeat needs exactly one of `count`, `for_each`, `while` or `until`"

schema RepeatAction(ActionBase):
    """RepeatAction repeats a sequence of actions.
    More info: https://www.home-assistant.io/docs/scripts/#repeat-a-group-of-actions

    Attributes
    ----------
    repeat: any, default is Undefined, required.
        Repeat holds the sequence and the loop kind, and is built as a Repeat.
    """
    repeat: any

    _repeat: any = Repeat {**repeat}

schema ParallelAction(ActionBase):
    """ParallelAction runs its branches at the same time.
    More info: https://www.home-assistant.io/docs/scripts/#parallelizing-actions

    Attributes
    ----------
    parallel: [any], default is Undefined, required.
        Parallel lists the branches. Each branch is an action, a
        `{sequence = [...]}` mapping, or a bare list of actions. Every action
        passes `coerce`.
    """
    parallel: [any]

    _parallel: [any] = [[coerce(_b) for _b in _a] if typeof(_a) == "list" else coerce(_a) for _a in parallel]

schema SequenceAction(ActionBase):
    """SequenceAction groups actions, typically as a `parallel` branch.
    More info: https://www.home-assistant.io/docs/scripts/#grouping-actions

    Attributes
    ----------
    sequence: [any], default is Undefined, required.
        Sequence is the grouped actions. Each entry passes `coerce`.
    """
    sequence: [any]

    _sequence: [any] = [coerce(_a) for _a in sequence]

schema VariablesAction(ActionBase):
    """VariablesAction defines or updates variables for the rest of the run.
    More info: https://www.home-assistant.io/docs/scripts/#variables

    Attributes
    ----------
    variables: {str:any}, default is Undefined, required.
        Variables maps each variable name to a value or a template.
    """
    variables: {str:any}

schema StopAction(ActionBase):
    """StopAction stops the run, optionally as an error.
    More info: https://www.home-assistant.io/docs/scripts/#stopping-a-script-sequence

    Attributes
    ----------
    stop: str, default is Undefined, required.
        Stop is the reason, which HA logs and shows in the trace.
    error: bool, default is Undefined, optional.
        Error marks the run as failed.
    response_variable: str, default is Undefined, optional.
        ResponseVariable names the variable that a script returns.
    """
    stop: str
    error?: bool
    response_variable?: str

    check:
        not (error and response_variable), "stop `response_variable` is not allowed with `error: true`"

schema EventAction(ActionBase):
    """EventAction fires an event on the event bus.
    More info: https://www.home-assistant.io/docs/scripts/#fire-an-event

    Attributes
    ----------
    event: str, default is Undefined, required.
        Event is the event type.
    event_data: {str:any}, default is Undefined, optional.
        EventData is the event's data. Templates are allowed.
    """
    event: str
    event_data?: {str:any}
