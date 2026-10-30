import regex
import models.frontend.common

schema StateTrigger(TriggerBase):
    """StateTrigger fires when an entity's state or attribute changes.
    More info: https://www.home-assistant.io/docs/automation/trigger/#state-trigger

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, required.
        EntityId is the watched entity or entities.
    from: any, default is Undefined, optional.
        From is the old state or a list of them. `None` emits `from: null`.
    not_from: any, default is Undefined, optional.
        NotFrom is an old state or a list of them that the trigger ignores.
    to: any, default is Undefined, optional.
        To is the new state or a list of them. `None` emits `to: null`, which
        fires on state changes and ignores attribute changes.
    not_to: any, default is Undefined, optional.
        NotTo is a new state or a list of them that the trigger ignores.
    attribute: str, default is Undefined, optional.
        Attribute watches an attribute instead of the state.
    for: str | int | float | {str:}, default is Undefined, optional.
        For requires the new state to hold for this duration.

    Examples
    --------
    {trigger = "state", entity_id = "binary_sensor.door", to = "on", $for.minutes = 5}
    """
    trigger: "state"
    entity_id: common.EntityIds
    from?: any
    not_from?: any
    to?: any
    not_to?: any
    attribute?: str
    $for?: common.Duration

    check:
        common.isEntityIds(entity_id), "state trigger `entity_id` must be entity ids, got `${entity_id}`"
        from is Undefined or not_from is Undefined, "state trigger `from` and `not_from` are mutually exclusive"
        to is Undefined or not_to is Undefined, "state trigger `to` and `not_to` are mutually exclusive"
        common.isDuration($for), "state trigger `for` must be HH:MM[:SS], seconds, a mapping or a template, got `${$for}`"

schema NumericStateTrigger(TriggerBase):
    """NumericStateTrigger fires when a numeric state or attribute crosses `above`
    or `below`.
    More info: https://www.home-assistant.io/docs/automation/trigger/#numeric-state-trigger

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, required.
        EntityId is the watched entity or entities.
    above: float | str, default is Undefined, optional.
        Above is a number, or the entity id of an `input_number`, `number`, or
        `sensor` that holds one.
    below: float | str, default is Undefined, optional.
        Below is a number, or the entity id of an `input_number`, `number`, or
        `sensor` that holds one.
    value_template: str, default is Undefined, optional.
        ValueTemplate transforms the value before the comparison.
    attribute: str, default is Undefined, optional.
        Attribute compares an attribute instead of the state.
    for: str | int | float | {str:}, default is Undefined, optional.
        For requires the value to stay past the threshold for this duration.
    """
    trigger: "numeric_state"
    entity_id: common.EntityIds
    above?: float | str
    below?: float | str
    value_template?: common.Template
    attribute?: str
    $for?: common.Duration

    check:
        common.isEntityIds(entity_id), "numeric_state trigger `entity_id` must be entity ids, got `${entity_id}`"
        above is not Undefined or below is not Undefined, "numeric_state trigger needs `above` or `below`"
        common.isDuration($for), "numeric_state trigger `for` must be HH:MM[:SS], seconds, a mapping or a template, got `${$for}`"

schema TimeTrigger(TriggerBase):
    """TimeTrigger fires at a time of day, or at the time an `input_datetime` or
    a timestamp sensor holds.
    More info: https://www.home-assistant.io/docs/automation/trigger/#time-trigger

    Attributes
    ----------
    at: any, default is Undefined, required.
        At is `HH:MM[:SS]`, an entity id, a template, a `{entity_id, offset}`
        mapping, or a list of those.
    weekday: Weekday | [Weekday], default is Undefined, optional.
        Weekday limits the trigger to days from `mon` to `sun`.
    """
    trigger: "time"
    at: any
    weekday?: common.Weekday | [common.Weekday]

    _ats: [any] = common.asList(at)

    check:
        all _t in _ats { typeof(_t) != "str" or regex.match(_t, common.TIME_OF_DAY) or "." in _t or "{{" in _t }, "time trigger `at` must be HH:MM[:SS], an entity id or a template, got `${at}`"

schema TimePatternTrigger(TriggerBase):
    """TimePatternTrigger fires when the clock matches a pattern, such as
    `minutes = "/5"` for every five minutes.
    More info: https://www.home-assistant.io/docs/automation/trigger/#time-pattern-trigger

    Attributes
    ----------
    hours: int | str, default is Undefined, optional.
        Hours is an hour, `*`, or a `/n` interval.
    minutes: int | str, default is Undefined, optional.
        Minutes is a minute, `*`, or a `/n` interval.
    seconds: int | str, default is Undefined, optional.
        Seconds is a second, `*`, or a `/n` interval.
    """
    trigger: "time_pattern"
    hours?: int | str
    minutes?: int | str
    seconds?: int | str

    check:
        hours is not Undefined or minutes is not Undefined or seconds is not Undefined, "time_pattern trigger needs `hours`, `minutes` or `seconds`"

schema SunTrigger(TriggerBase):
    """SunTrigger fires at sunrise or sunset. The purpose-specific triggers such
    as `sun.sunset` replace it.
    More info: https://www.home-assistant.io/docs/automation/trigger/#sun-trigger

    Attributes
    ----------
    event: "sunrise" | "sunset", default is Undefined, required.
        Event selects sunrise or sunset.
    offset: str | int | float | {str:}, default is Undefined, optional.
        Offset shifts the trigger, such as `-00:30:00`.
    """
    trigger: "sun"
    event: "sunrise" | "sunset"
    offset?: common.Duration

    check:
        common.isDuration(offset), "sun trigger `offset` must be [-]HH:MM[:SS], seconds or a mapping, got `${offset}`"

schema EventTrigger(TriggerBase):
    """EventTrigger fires when an event of a given type reaches the event bus.
    More info: https://www.home-assistant.io/docs/automation/trigger/#event-trigger

    Attributes
    ----------
    event_type: str | [str], default is Undefined, required.
        EventType is the event type or a list of them.
    event_data: {str:any}, default is Undefined, optional.
        EventData must match the event's data.
    context: {str:any}, default is Undefined, optional.
        Context must match the event's context, such as `user_id`.
    """
    trigger: "event"
    event_type: str | [str]
    event_data?: {str:any}
    context?: {str:any}

schema HomeAssistantTrigger(TriggerBase):
    """HomeAssistantTrigger fires when Home Assistant starts or shuts down.
    More info: https://www.home-assistant.io/docs/automation/trigger/#home-assistant-trigger

    Attributes
    ----------
    event: "start" | "shutdown", default is Undefined, required.
        Event selects startup or shutdown.
    """
    trigger: "homeassistant"
    event: "start" | "shutdown"

schema TemplateTrigger(TriggerBase):
    """TemplateTrigger fires when a template's result turns true.
    More info: https://www.home-assistant.io/docs/automation/trigger/#template-trigger

    Attributes
    ----------
    value_template: str, default is Undefined, required.
        ValueTemplate is the template to watch.
    for: str | int | float | {str:}, default is Undefined, optional.
        For requires the template to stay true for this duration.
    """
    trigger: "template"
    value_template: common.Template
    $for?: common.Duration

    check:
        common.isDuration($for), "template trigger `for` must be HH:MM[:SS], seconds, a mapping or a template, got `${$for}`"

schema MqttTrigger(TriggerBase):
    """MqttTrigger fires when an MQTT message arrives on a topic.
    More info: https://www.home-assistant.io/docs/automation/trigger/#mqtt-trigger

    Attributes
    ----------
    topic: str, default is Undefined, required.
        Topic is the MQTT topic, and it can contain wildcards.
    payload: str, default is Undefined, optional.
        Payload must match the message payload.
    value_template: str, default is Undefined, optional.
        ValueTemplate transforms the payload before the `payload` comparison.
    encoding: str, default is Undefined, optional.
        Encoding is the payload encoding. An empty string keeps raw bytes.
    qos: 0 | 1 | 2, default is Undefined, optional.
        Qos is the subscription's quality of service.
    """
    trigger: "mqtt"
    topic: str
    payload?: str
    value_template?: common.Template
    encoding?: str
    qos?: 0 | 1 | 2

schema WebhookTrigger(TriggerBase):
    """WebhookTrigger fires when HA receives a request on a webhook URL. Keep the
    `webhook_id` in secrets with `tags.secret`.
    More info: https://www.home-assistant.io/docs/automation/trigger/#webhook-trigger

    Attributes
    ----------
    webhook_id: str, default is Undefined, required.
        WebhookId is the last path segment of the webhook URL.
    allowed_methods: ["GET" | "HEAD" | "POST" | "PUT"], default is Undefined, optional.
        AllowedMethods lists the HTTP methods the webhook accepts.
    local_only: bool, default is Undefined, optional.
        LocalOnly rejects requests from outside the local network.
    """
    trigger: "webhook"
    webhook_id: str
    allowed_methods?: ["GET" | "HEAD" | "POST" | "PUT"]
    local_only?: bool

schema ZoneTrigger(TriggerBase):
    """ZoneTrigger fires when a person or device tracker enters or leaves a zone.
    The purpose-specific `zone.*` triggers replace it.
    More info: https://www.home-assistant.io/docs/automation/trigger/#zone-trigger

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, required.
        EntityId is the watched person or device tracker.
    zone: str, default is Undefined, required.
        Zone is the zone's entity id, such as `zone.home`.
    event: "enter" | "leave", default is Undefined, optional.
        Event selects entering or leaving. HA defaults to `enter`.
    """
    trigger: "zone"
    entity_id: common.EntityIds
    zone: str
    event?: "enter" | "leave"

    check:
        common.isEntityIds(entity_id), "zone trigger `entity_id` must be entity ids, got `${entity_id}`"
