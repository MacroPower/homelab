import regex

import models.frontend.common

# INPUT_ENTITY_ID is HA's `INPUT_ENTITY_ID` from `helpers/config_validation.py`.
# A state condition whose `state` matches it compares against that helper's
# state, and HA rejects `for` on such a condition.
INPUT_ENTITY_ID = r"^input_(?:select|text|number|boolean|datetime)\.(?!.+__)(?!_)[\da-z_]+(?<!_)$"

schema LogicCondition(ConditionBase):
    """LogicCondition combines nested conditions with `and`, `or`, or `not`.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#logical-conditions

    Attributes
    ----------
    condition: "and" | "or" | "not", default is Undefined, required.
        Condition selects the logical operator.
    conditions: [any], default is Undefined, required.
        Conditions are the nested conditions. Each entry passes `coerce`.

    Examples
    --------
    {condition = "or", conditions = [
        {condition = "state", entity_id = "person.a", state = "home"}
        "{{ is_state('person.b', 'home') }}"
    ]}
    """
    condition: "and" | "or" | "not"
    conditions: [any]

    _conditions: [any] = [coerce(_c) for _c in conditions]

schema StateCondition(ConditionBase):
    """StateCondition tests an entity's state or attribute.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#state-condition

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, required.
        EntityId is the tested entity or entities.
    state: any, default is Undefined, required.
        State is the expected state, a list of them, or the entity id of an
        `input_*` helper whose state is expected. Without `attribute`, each
        state must be a string, so quote a number as `"5"`.
    attribute: str, default is Undefined, optional.
        Attribute tests an attribute instead of the state.
    match: "all" | "any", default is Undefined, optional.
        Match decides whether all or any of the entities must match. HA
        defaults to `all`.
    for: str | int | float | {str:}, default is Undefined, optional.
        For requires the state to have held for this duration. HA rejects it
        with `attribute` or with a `state` that names an `input_*` helper.
    """
    condition: "state"
    entity_id: common.EntityIds
    state: any
    attribute?: str
    match?: "all" | "any"
    $for?: common.Duration

    _states: [any] = common.asList(state)
    _helperStates: [any] = [_s for _s in _states if typeof(_s) == "str" and regex.match(_s, INPUT_ENTITY_ID)]

    check:
        common.isEntityIds(entity_id), "state condition `entity_id` must be entity ids, got `${entity_id}`"
        attribute is not Undefined or all _s in _states { typeof(_s) == "str" }, "state condition `state` must be a string or a list of strings without `attribute`, got `${state}`"
        $for is Undefined or attribute is Undefined, "state condition `for` cannot be combined with `attribute`"
        $for is Undefined or not _helperStates, "state condition `for` cannot be combined with a `state` that names an `input_*` helper, got ${_helperStates}"
        common.isDuration($for), "state condition `for` must be HH:MM[:SS], seconds, a mapping or a template, got `${$for}`"

schema NumericStateCondition(ConditionBase):
    """NumericStateCondition tests a numeric state or attribute against `above`
    and `below`.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#numeric-state-condition

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, required.
        EntityId is the tested entity or entities.
    above: float | str, default is Undefined, optional.
        Above is a number, or the entity id of an `input_number`, `number`, or
        `sensor` that holds one.
    below: float | str, default is Undefined, optional.
        Below is a number, or the entity id of an `input_number`, `number`, or
        `sensor` that holds one.
    attribute: str, default is Undefined, optional.
        Attribute tests an attribute instead of the state.
    value_template: str, default is Undefined, optional.
        ValueTemplate transforms the value before the comparison.
    """
    condition: "numeric_state"
    entity_id: common.EntityIds
    above?: float | str
    below?: float | str
    attribute?: str
    value_template?: common.Template

    check:
        common.isEntityIds(entity_id), "numeric_state condition `entity_id` must be entity ids, got `${entity_id}`"
        above is not Undefined or below is not Undefined, "numeric_state condition needs `above` or `below`"

schema TemplateCondition(ConditionBase):
    """TemplateCondition passes when its template renders true. A bare template
    string in a condition list is shorthand for it.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#template-condition

    Attributes
    ----------
    value_template: str, default is Undefined, required.
        ValueTemplate is the template to render.
    """
    condition: "template"
    value_template: common.Template

schema TimeCondition(ConditionBase):
    """TimeCondition tests the time of day and the weekday.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#time-condition

    Attributes
    ----------
    after: str, default is Undefined, optional.
        After is `HH:MM[:SS]` or the entity id of an `input_datetime` or a
        timestamp sensor.
    before: str, default is Undefined, optional.
        Before is `HH:MM[:SS]` or the entity id of an `input_datetime` or a
        timestamp sensor.
    weekday: Weekday | [Weekday], default is Undefined, optional.
        Weekday limits the condition to days from `mon` to `sun`.
    """
    condition: "time"
    after?: str
    before?: str
    weekday?: common.Weekday | [common.Weekday]

    check:
        after or before or weekday, "time condition needs `after`, `before` or `weekday`"
        after is Undefined or regex.match(after, common.TIME_OF_DAY) or "." in after, "time condition `after` must be HH:MM[:SS] or an entity id, got `${after}`"
        before is Undefined or regex.match(before, common.TIME_OF_DAY) or "." in before, "time condition `before` must be HH:MM[:SS] or an entity id, got `${before}`"

schema TriggerCondition(ConditionBase):
    """TriggerCondition tests which trigger started the run, by trigger id.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#trigger-condition

    Attributes
    ----------
    id: str | [str], default is Undefined, required.
        Id is a trigger id or a list of them.
    """
    condition: "trigger"
    id: str | [str]

schema SunCondition(ConditionBase):
    """SunCondition tests the time relative to sunrise and sunset. The
    purpose-specific conditions such as `sun.is_up` replace it.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#sun-condition

    Attributes
    ----------
    after: "sunrise" | "sunset", default is Undefined, optional.
        After passes after the sun event.
    before: "sunrise" | "sunset", default is Undefined, optional.
        Before passes before the sun event.
    after_offset: str | int | float | {str:}, default is Undefined, optional.
        AfterOffset shifts the `after` event.
    before_offset: str | int | float | {str:}, default is Undefined, optional.
        BeforeOffset shifts the `before` event.
    """
    condition: "sun"
    after?: "sunrise" | "sunset"
    before?: "sunrise" | "sunset"
    after_offset?: common.Duration
    before_offset?: common.Duration

    check:
        after or before, "sun condition needs `after` or `before`"
        common.isDuration(after_offset), "sun condition `after_offset` must be [-]HH:MM[:SS], seconds or a mapping, got `${after_offset}`"
        common.isDuration(before_offset), "sun condition `before_offset` must be [-]HH:MM[:SS], seconds or a mapping, got `${before_offset}`"

schema ZoneCondition(ConditionBase):
    """ZoneCondition tests whether a person or device tracker is in a zone. The
    purpose-specific `zone.*` conditions replace it.
    More info: https://www.home-assistant.io/docs/scripts/conditions/#zone-condition

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, required.
        EntityId is the tested person or device tracker.
    zone: str | [str], default is Undefined, required.
        Zone is a zone's entity id or a list of them.
    """
    condition: "zone"
    entity_id: common.EntityIds
    zone: str | [str]

    check:
        common.isEntityIds(entity_id), "zone condition `entity_id` must be entity ids, got `${entity_id}`"
