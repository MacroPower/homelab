import runtime

import models.frontend.action
import models.frontend.automation
import models.frontend.common
import models.frontend.condition
import models.frontend.helper
import models.frontend.script
import models.frontend.template
import models.frontend.trigger

# _MODELLED_DOMAINS lists the domain keys that the package mixins write.
_MODELLED_DOMAINS = ["homeassistant", "automation", "script", "template", "input_boolean", "input_button", "input_number", "input_select", "input_text", "input_datetime", "timer", "counter", "schedule"]

# _RESERVED_SCRIPT_KEYS are the names of the `script` domain's own actions.
_RESERVED_SCRIPT_KEYS = ["reload", "turn_on", "turn_off", "toggle"]

schema Package:
    """Package is one Home Assistant package, rendered to `packages/<name>.yaml`.
    Every collection is a map keyed by HA object id, so an overlay can patch or
    delete one entry by key. Keys must be HA slugs (`[a-z0-9_]`, with no
    leading, trailing, or double `_`), because each key becomes an object id
    unchanged. Keys are part of the config's interface, because renaming one
    changes the entity id or the unique id that HA registered.

    Package validates every trigger, condition, and action list in its own
    body, and reports every invalid entry with its key path, such as
    `automations.motion_light.triggers[0]`.
    More info: https://www.home-assistant.io/docs/configuration/packages/

    Attributes
    ----------
    name: str, required.
        Name is the package name and the file stem. It must be a slug and equal
        the package's key in `HomeAssistant.packages`.
    automations: {str:automation.Automation}, default is Undefined, optional.
        Automations are keyed by id suffix, so the id becomes `<name>.<key>`.
    scripts: {str:script.Script}, default is Undefined, optional.
        Scripts are keyed by object id, as in `script.<key>`. The keys
        `reload`, `turn_on`, `turn_off`, and `toggle` are reserved.
    templates: {str:template.TemplateSection}, default is Undefined, optional.
        Templates are the `template:` sections. Each key is a handle for
        overlays and is not emitted.
    inputBooleans: {str:helper.InputBoolean}, default is Undefined, optional.
        InputBooleans are keyed by object id, as in `input_boolean.<key>`.
    inputButtons: {str:helper.InputButton}, default is Undefined, optional.
        InputButtons are keyed by object id, as in `input_button.<key>`.
    inputNumbers: {str:helper.InputNumber}, default is Undefined, optional.
        InputNumbers are keyed by object id, as in `input_number.<key>`.
    inputSelects: {str:helper.InputSelect}, default is Undefined, optional.
        InputSelects are keyed by object id, as in `input_select.<key>`.
    inputTexts: {str:helper.InputText}, default is Undefined, optional.
        InputTexts are keyed by object id, as in `input_text.<key>`.
    inputDatetimes: {str:helper.InputDatetime}, default is Undefined, optional.
        InputDatetimes are keyed by object id, as in `input_datetime.<key>`.
    timers: {str:helper.Timer}, default is Undefined, optional.
        Timers are keyed by object id, as in `timer.<key>`.
    counters: {str:helper.Counter}, default is Undefined, optional.
        Counters are keyed by object id, as in `counter.<key>`.
    schedules: {str:helper.Schedule}, default is Undefined, optional.
        Schedules are keyed by object id, as in `schedule.<key>`.
    customize: {str:{str:any}}, default is Undefined, optional.
        Customize is emitted as the package's `homeassistant: customize:` block,
        keyed by entity id.
    extraConfig: {str:any}, default is {}, optional.
        ExtraConfig is emitted into the package verbatim, for integrations that
        haconfig does not model. Its keys must not be a domain that the package
        models. A labelled key such as `automation raw` holds hand-written
        entries of a modelled domain.
    getEntityId: (str, str) -> str
        GetEntityId returns `<domain>.<key>` for an entry of this package, and
        fails when the entry does not exist. Other packages use it to
        reference this one. A package cannot call it on itself during
        construction.

    Examples
    --------
    hallway = frontend.Package {
        name = "hallway"
        inputBooleans.hallway_light_override = {name = "Hallway light override"}
        timers.hallway_light = {duration = "00:05:00"}
    }
    """
    name: str
    automations?: {str:automation.Automation}
    scripts?: {str:script.Script}
    templates?: {str:template.TemplateSection}
    inputBooleans?: {str:helper.InputBoolean}
    inputButtons?: {str:helper.InputButton}
    inputNumbers?: {str:helper.InputNumber}
    inputSelects?: {str:helper.InputSelect}
    inputTexts?: {str:helper.InputText}
    inputDatetimes?: {str:helper.InputDatetime}
    timers?: {str:helper.Timer}
    counters?: {str:helper.Counter}
    schedules?: {str:helper.Schedule}
    customize?: {str:{str:any}}
    extraConfig?: {str:any} = {}

    # Every live entry with an object id, keyed by HA domain and then by object
    # id. An overlay deletion (`= Undefined`) still iterates, so each map drops
    # falsy entries, as the mixins do.
    _objects: {str:{str:any}} = {
        automation = {_k: _v for _k, _v in automations or {} if _v}
        script = {_k: _v for _k, _v in scripts or {} if _v}
        input_boolean = {_k: _v for _k, _v in inputBooleans or {} if _v}
        input_button = {_k: _v for _k, _v in inputButtons or {} if _v}
        input_number = {_k: _v for _k, _v in inputNumbers or {} if _v}
        input_select = {_k: _v for _k, _v in inputSelects or {} if _v}
        input_text = {_k: _v for _k, _v in inputTexts or {} if _v}
        input_datetime = {_k: _v for _k, _v in inputDatetimes or {} if _v}
        timer = {_k: _v for _k, _v in timers or {} if _v}
        counter = {_k: _v for _k, _v in counters or {} if _v}
        schedule = {_k: _v for _k, _v in schedules or {} if _v}
        sensor = {_k: _v for _, _s in templates or {} if _s for _k, _v in _s.sensors or {} if _v}
        binary_sensor = {_k: _v for _, _s in templates or {} if _s for _k, _v in _s.binarySensors or {} if _v}
        switch = {_k: _v for _, _s in templates or {} if _s for _k, _v in _s.switches or {} if _v}
        button = {_k: _v for _, _s in templates or {} if _s for _k, _v in _s.buttons or {} if _v}
        number = {_k: _v for _, _s in templates or {} if _s for _k, _v in _s.numbers or {} if _v}
        select = {_k: _v for _, _s in templates or {} if _s for _k, _v in _s.selects or {} if _v}
        **{_d: {_k: _v for _, _s in templates or {} if _s for _k, _v in (_s.entities or {})[_d] or {} if _v} for _, _s0 in templates or {} if _s0 for _d in _s0.entities or {}}
    }

    # Every trigger, condition, and action list entry, with the key path that
    # the user wrote. Required lists carry an `or []` guard, so a missing list
    # reaches KCL's required-attribute check instead of failing here.
    #
    # Validation runs here, in the schema body, and never in a lambda. On KCL
    # 0.11, a `runtime.catch` closure inside a lambda sees the previous call's
    # arguments after the first caught error. The stale arguments mask a later
    # error.
    _polymorphic: [{str:any}] = [
        *[{path = "automations.${_k}.triggers[${_i}]", kind = "trigger", item = _x} for _k, _a in automations or {} if _a for _i, _x in _a.triggers or []]
        *[{path = "automations.${_k}.conditions[${_i}]", kind = "condition", item = _x} for _k, _a in automations or {} if _a for _i, _x in _a.conditions or []]
        *[{path = "automations.${_k}.actions[${_i}]", kind = "action", item = _x} for _k, _a in automations or {} if _a for _i, _x in _a.actions or []]
        *[{path = "scripts.${_k}.sequence[${_i}]", kind = "action", item = _x} for _k, _s in scripts or {} if _s for _i, _x in _s.sequence or []]
        *[{path = "templates.${_k}.triggers[${_i}]", kind = "trigger", item = _x} for _k, _t in templates or {} if _t for _i, _x in _t.triggers or []]
        *[{path = "templates.${_k}.conditions[${_i}]", kind = "condition", item = _x} for _k, _t in templates or {} if _t for _i, _x in _t.conditions or []]
        *[{path = "templates.${_k}.actions[${_i}]", kind = "action", item = _x} for _k, _t in templates or {} if _t for _i, _x in _t.actions or []]
        *[{path = "templates.${_k}.switches.${_e}.${_f}[${_i}]", kind = "action", item = _x} for _k, _t in templates or {} if _t for _e, _sw in _t.switches or {} if _sw for _f in ["turn_on", "turn_off"] for _i, _x in _sw[_f] or []]
        *[{path = "templates.${_k}.buttons.${_e}.press[${_i}]", kind = "action", item = _x} for _k, _t in templates or {} if _t for _e, _b in _t.buttons or {} if _b for _i, _x in _b.press or []]
        *[{path = "templates.${_k}.numbers.${_e}.set_value[${_i}]", kind = "action", item = _x} for _k, _t in templates or {} if _t for _e, _n in _t.numbers or {} if _n for _i, _x in _n.set_value or []]
        *[{path = "templates.${_k}.selects.${_e}.select_option[${_i}]", kind = "action", item = _x} for _k, _t in templates or {} if _t for _e, _sl in _t.selects or {} if _sl for _i, _x in _sl.select_option or []]
        *[{path = "templates.${_k}.${_f}.${_e}.conditions[${_i}]", kind = "condition", item = _x} for _k, _t in templates or {} if _t for _f in ["sensors", "binarySensors", "switches", "buttons", "numbers", "selects"] for _e, _en in _t[_f] or {} if _en for _i, _x in _en.conditions or []]
        *[{path = "templates.${_k}.entities.${_d}.${_e}.conditions[${_i}]", kind = "condition", item = _x} for _k, _t in templates or {} if _t for _d, _es in _t.entities or {} for _e, _en in _es or {} if _en for _i, _x in _en.conditions or []]
    ]
    _caught: [{str:any}] = [{path = _p.path, err = runtime.catch(lambda { _coerceKind(_p.kind, _p.item) })} for _p in _polymorphic]
    _errors: [str] = ["{}: {}".format(_c.path, _c.err) for _c in _caught if _c.err]
    _errorText: str = "package `{}` has invalid entries:\n  {}".format(name, "\n  ".join(_errors))

    _badKeys: [str] = [_k for _, _m in _objects for _k in _m if not common.isSlug(_k)]
    _modelledExtraKeys: [str] = [_k for _k in extraConfig or {} if _k in _MODELLED_DOMAINS]
    _reservedScriptKeys: [str] = [_k for _k in scripts or {} if _k in _RESERVED_SCRIPT_KEYS]

    getEntityId: (str, str) -> str = lambda domain: str, key: str -> str {
        assert domain in _objects and key in _objects[domain], "package `${name}` has no `${domain}` entry `${key}`"
        "${domain}.${key}"
    }

    check:
        not _errors, _errorText
        common.isSlug(name), "package name must be a slug, got `${name}`"
        not _badKeys, "every key in package `${name}` must be a slug ([a-z0-9_]); got ${_badKeys}"
        not _modelledExtraKeys, "extraConfig must not set ${_modelledExtraKeys}, a domain this package models; use a labelled key such as `automation raw`"
        not _reservedScriptKeys, "script keys ${_reservedScriptKeys} are reserved; `reload`, `turn_on`, `turn_off` and `toggle` are actions of the script domain"

# _coerceKind routes one entry to the dispatcher of its family. Package calls
# it inside `runtime.catch` in its schema body.
_coerceKind = lambda kind: str, item: any -> any {
    trigger.coerce(item) if kind == "trigger" else (condition.coerce(item) if kind == "condition" else action.coerce(item))
}
