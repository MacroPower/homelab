import regex

# TYPED_DOMAINS lists the template domains that have a typed schema and a typed
# map on TemplateSection.
TYPED_DOMAINS: [str] = ["sensor", "binary_sensor", "switch", "button", "number", "select"]

schema TemplateEntity:
    """TemplateEntity holds the keys that every template entity accepts. HA 2026.10
    rejects `object_id`, so the schema has no such field.
    More info: https://www.home-assistant.io/integrations/template/

    Attributes
    ----------
    name: str, default is Undefined, optional.
        Name is the friendly name. A template is allowed.
    unique_id: str, default is "<package>.<key>", optional.
        UniqueId registers the entity. The TemplateMixin derives it from the
        package name and the map key.
    default_entity_id: str, default is "<domain>.<key>", optional.
        DefaultEntityId is the entity id HA uses when it first registers the
        entity. The TemplateMixin derives it from the domain and the map key.
        A typed entity's value must start with its own domain.
    icon: str, default is Undefined, optional.
        Icon is an icon name or a template.
    picture: str, default is Undefined, optional.
        Picture is an image URL or a template.
    availability: str, default is Undefined, optional.
        Availability is a template. A false result marks the entity unavailable.
    attributes: {str:str}, default is Undefined, optional.
        Attributes maps each attribute name to a template.
    variables: {str:any}, default is Undefined, optional.
        Variables are available to the entity's templates.
    conditions: [any], default is Undefined, optional.
        Conditions must all pass for the entity to update. They require a
        trigger-based section. `Package` passes each entry through
        `condition.coerce`.
    """
    name?: str
    unique_id?: str
    default_entity_id?: str
    icon?: str
    picture?: str
    availability?: str
    attributes?: {str:str}
    variables?: {str:any}
    conditions?: [any]

    # Each typed subclass sets its HA domain, which the check below compares
    # with a user-set default_entity_id.
    _domain?: str

    check:
        default_entity_id is Undefined or _domain is Undefined or default_entity_id.startswith(_domain + "."), "template `default_entity_id` must be in the `${_domain}` domain, got `${default_entity_id}`"

schema TemplateSensor(TemplateEntity):
    """TemplateSensor is a template `sensor`.
    More info: https://www.home-assistant.io/integrations/template/#sensor

    Attributes
    ----------
    state: str, default is Undefined, required.
        State is the template that renders the sensor's value.
    device_class: str, default is Undefined, optional.
        DeviceClass sets the sensor's device class, such as `temperature`.
    state_class: "measurement" | "measurement_angle" | "total" | "total_increasing", default is Undefined, optional.
        StateClass enables long-term statistics.
    unit_of_measurement: str, default is Undefined, optional.
        UnitOfMeasurement is the value's unit.
    last_reset: str, default is Undefined, optional.
        LastReset is a template for the last reset time. It requires
        `state_class: total`.
    """
    _domain = "sensor"
    state: str
    device_class?: str
    state_class?: "measurement" | "measurement_angle" | "total" | "total_increasing"
    unit_of_measurement?: str
    last_reset?: str

    check:
        last_reset is Undefined or state_class == "total", "template sensor `last_reset` requires `state_class: total`"

schema TemplateBinarySensor(TemplateEntity):
    """TemplateBinarySensor is a template `binary_sensor`.
    More info: https://www.home-assistant.io/integrations/template/#binary-sensor

    Attributes
    ----------
    state: str, default is Undefined, required.
        State is the template that renders on or off.
    device_class: str, default is Undefined, optional.
        DeviceClass sets the sensor's device class, such as `motion`.
    unit_of_measurement: str, default is Undefined, optional.
        UnitOfMeasurement is the unit shown next to the state.
    delay_on: str | int | {str:int | float}, default is Undefined, optional.
        DelayOn is how long the state must be on before the sensor turns on.
    delay_off: str | int | {str:int | float}, default is Undefined, optional.
        DelayOff is how long the state must be off before the sensor turns off.
    auto_off: str | int | {str:int | float}, default is Undefined, optional.
        AutoOff turns the sensor off after this duration. It applies only to a
        trigger-based section.
    """
    _domain = "binary_sensor"
    state: str
    device_class?: str
    unit_of_measurement?: str
    delay_on?: str | int | {str:int | float}
    delay_off?: str | int | {str:int | float}
    auto_off?: str | int | {str:int | float}

schema TemplateSwitch(TemplateEntity):
    """TemplateSwitch is a template `switch`. `Package` validates its action lists.
    More info: https://www.home-assistant.io/integrations/template/#switch

    Attributes
    ----------
    state: str, default is Undefined, optional.
        State is the template that renders on or off. Without it, the switch
        is optimistic.
    turn_on: [any], default is Undefined, optional.
        TurnOn lists the actions that turn the switch on.
    turn_off: [any], default is Undefined, optional.
        TurnOff lists the actions that turn the switch off.
    optimistic: bool, default is Undefined, optional.
        Optimistic updates the state immediately after an action.
    """
    _domain = "switch"
    state?: str
    turn_on?: [any]
    turn_off?: [any]
    optimistic?: bool

schema TemplateButton(TemplateEntity):
    """TemplateButton is a template `button`. Trigger-based sections cannot hold
    buttons. `Package` validates its action list.
    More info: https://www.home-assistant.io/integrations/template/#button

    Attributes
    ----------
    press: [any], default is Undefined, required.
        Press lists the actions that run when the button is pressed.
    device_class: str, default is Undefined, optional.
        DeviceClass sets the button's device class, such as `restart`.
    """
    _domain = "button"
    press: [any]
    device_class?: str

schema TemplateNumber(TemplateEntity):
    """TemplateNumber is a template `number`. `Package` validates its action list.
    More info: https://www.home-assistant.io/integrations/template/#number

    Attributes
    ----------
    state: str, default is Undefined, optional.
        State is the template that renders the value.
    set_value: [any], default is Undefined, required.
        SetValue lists the actions that set the value, readable as `value`.
    min: str | float, default is Undefined, optional.
        Min is the lowest value, or a template.
    max: str | float, default is Undefined, optional.
        Max is the highest value, or a template.
    step: str | float, default is Undefined, optional.
        Step is the increment, or a template.
    unit_of_measurement: str, default is Undefined, optional.
        UnitOfMeasurement is the value's unit.
    device_class: str, default is Undefined, optional.
        DeviceClass sets the number's device class, such as `temperature`.
    optimistic: bool, default is Undefined, optional.
        Optimistic updates the state immediately after `set_value`.
    """
    _domain = "number"
    state?: str
    set_value: [any]
    min?: str | float
    max?: str | float
    step?: str | float
    unit_of_measurement?: str
    device_class?: str
    optimistic?: bool

schema TemplateSelect(TemplateEntity):
    """TemplateSelect is a template `select`. `Package` validates its action list.
    More info: https://www.home-assistant.io/integrations/template/#select

    Attributes
    ----------
    options: str, default is Undefined, required.
        Options is a template that renders the list of options.
    state: str, default is Undefined, optional.
        State is the template that renders the selected option.
    select_option: [any], default is Undefined, optional.
        SelectOption lists the actions that select an option, readable as
        `option`.
    optimistic: bool, default is Undefined, optional.
        Optimistic updates the state immediately after `select_option`.
    """
    _domain = "select"
    options: str
    state?: str
    select_option?: [any]
    optimistic?: bool

schema GenericTemplateEntity(TemplateEntity):
    """GenericTemplateEntity is a template entity of a domain that haconfig does
    not type, such as `image`, `weather`, `light`, `fan`, `cover`, `lock`,
    `vacuum`, `alarm_control_panel`, `event`, or `update`. Only the
    TemplateEntity keys are checked, and every other key is emitted verbatim.
    """
    [str]: any

schema TemplateSection:
    """TemplateSection is one entry of the `template:` list. A section with
    `triggers` makes every entity in it trigger-based, and a section without
    them makes every entity state-based. Each entity map is keyed by object id.
    More info: https://www.home-assistant.io/integrations/template/

    Attributes
    ----------
    triggers: [any], default is Undefined, optional.
        Triggers make the section trigger-based. Each entry passes
        `trigger.coerce`.
    conditions: [any], default is Undefined, optional.
        Conditions gate an update of a trigger-based section. Each entry
        passes `condition.coerce`.
    actions: [any], default is Undefined, optional.
        Actions run after a trigger and before the update. Each entry passes
        `action.coerce`.
    variables: {str:any}, default is Undefined, optional.
        Variables are available to every entity in the section.
    sensors: {str:TemplateSensor}, default is Undefined, optional.
        Sensors are the section's `sensor` entities.
    binarySensors: {str:TemplateBinarySensor}, default is Undefined, optional.
        BinarySensors are the section's `binary_sensor` entities.
    switches: {str:TemplateSwitch}, default is Undefined, optional.
        Switches are the section's `switch` entities.
    buttons: {str:TemplateButton}, default is Undefined, optional.
        Buttons are the section's `button` entities.
    numbers: {str:TemplateNumber}, default is Undefined, optional.
        Numbers are the section's `number` entities.
    selects: {str:TemplateSelect}, default is Undefined, optional.
        Selects are the section's `select` entities.
    entities: {str:{str:GenericTemplateEntity}}, default is Undefined, optional.
        Entities holds the template domains without a typed map, keyed by HA
        domain and then by object id.

    Examples
    --------
    templates.lux.sensors.hallway_lux = {
        unit_of_measurement = "lx"
        state = "{{ states('sensor.hallway_sensor_illuminance') }}"
    }
    """
    triggers?: [any]
    conditions?: [any]
    actions?: [any]
    variables?: {str:any}

    sensors?: {str:TemplateSensor}
    binarySensors?: {str:TemplateBinarySensor}
    switches?: {str:TemplateSwitch}
    buttons?: {str:TemplateButton}
    numbers?: {str:TemplateNumber}
    selects?: {str:TemplateSelect}
    entities?: {str:{str:GenericTemplateEntity}}

    _binarySensors: [any] = [_b for _, _b in binarySensors or {} if _b]
    _allEntities: [any] = [_e for _m in [sensors, binarySensors, switches, buttons, numbers, selects] for _, _e in _m or {} if _e] + [_e for _, _es in entities or {} for _, _e in _es or {} if _e]
    _conditionalEntities: [any] = [_e for _e in _allEntities if _e.conditions]
    _otherDomains: [str] = [_d for _d in entities or {}]
    _typedDomains: [str] = [_d for _d in _otherDomains if _d in TYPED_DOMAINS]
    _badDomains: [str] = [_d for _d in _otherDomains if not regex.match(_d, r"^[a-z_]+$")]

    check:
        triggers or not (conditions or actions), "template `conditions` and `actions` require `triggers`"
        not (triggers and buttons), "template buttons are not allowed in a trigger-based section"
        triggers or all _b in _binarySensors { not _b?.auto_off }, "template binary sensor `auto_off` requires a trigger-based section"
        triggers or not _conditionalEntities, "template entity `conditions` require a trigger-based section"
        not _typedDomains, "use the typed map for ${_typedDomains}, not `entities`"
        not _badDomains, "`entities` keys must be HA domains, got ${_badDomains}"
