import models.protocol
import models.resource

# One mixin per helper domain, grouped in one file like konfig's rbac_mixin.k.
# HA merges helper maps across packages, so each key is the object id
# unchanged. Each mixin filters overlay deletions (`= Undefined`) before its
# guard, so deleting the last entry of a domain emits nothing.
#
# HA's package merge skips an empty mapping below the domain key without a
# message, so HA never creates a helper written as `{}`. Each mixin emits such
# an entry as `null`. Every helper domain that allows an entry without options
# accepts `null` for it.

# _helperEntry returns the helper, or None when it sets no attribute. Its names
# carry the `_he` prefix, because a name inside a lambda's comprehension
# resolves to a same-named attribute of the calling schema first.
_helperEntry = lambda _heEntry: any -> any {
    _heSet = [_heK for _heK, _heV in _heEntry if not _heK.startswith("_") and _heV is not Undefined]
    _heEntry if _heSet else None
}

mixin InputBooleanMixin for protocol.PackageProtocol:
    """InputBooleanMixin writes the package's `inputBooleans` to the `input_boolean:` map."""
    _liveInputBooleans = {_k: _c for _k, _c in config.inputBooleans or {} if _c}
    if _liveInputBooleans:
        hass: resource.DomainMapping {input_boolean = {_k: _helperEntry(_c) for _k, _c in _liveInputBooleans}}

mixin InputButtonMixin for protocol.PackageProtocol:
    """InputButtonMixin writes the package's `inputButtons` to the `input_button:` map."""
    _liveInputButtons = {_k: _c for _k, _c in config.inputButtons or {} if _c}
    if _liveInputButtons:
        hass: resource.DomainMapping {input_button = {_k: _helperEntry(_c) for _k, _c in _liveInputButtons}}

mixin InputNumberMixin for protocol.PackageProtocol:
    """InputNumberMixin writes the package's `inputNumbers` to the `input_number:` map."""
    _liveInputNumbers = {_k: _c for _k, _c in config.inputNumbers or {} if _c}
    if _liveInputNumbers:
        hass: resource.DomainMapping {input_number = {_k: _helperEntry(_c) for _k, _c in _liveInputNumbers}}

mixin InputSelectMixin for protocol.PackageProtocol:
    """InputSelectMixin writes the package's `inputSelects` to the `input_select:` map."""
    _liveInputSelects = {_k: _c for _k, _c in config.inputSelects or {} if _c}
    if _liveInputSelects:
        hass: resource.DomainMapping {input_select = {_k: _helperEntry(_c) for _k, _c in _liveInputSelects}}

mixin InputTextMixin for protocol.PackageProtocol:
    """InputTextMixin writes the package's `inputTexts` to the `input_text:` map."""
    _liveInputTexts = {_k: _c for _k, _c in config.inputTexts or {} if _c}
    if _liveInputTexts:
        hass: resource.DomainMapping {input_text = {_k: _helperEntry(_c) for _k, _c in _liveInputTexts}}

mixin InputDatetimeMixin for protocol.PackageProtocol:
    """InputDatetimeMixin writes the package's `inputDatetimes` to the `input_datetime:` map."""
    _liveInputDatetimes = {_k: _c for _k, _c in config.inputDatetimes or {} if _c}
    if _liveInputDatetimes:
        hass: resource.DomainMapping {input_datetime = {_k: _helperEntry(_c) for _k, _c in _liveInputDatetimes}}

mixin TimerMixin for protocol.PackageProtocol:
    """TimerMixin writes the package's `timers` to the `timer:` map."""
    _liveTimers = {_k: _c for _k, _c in config.timers or {} if _c}
    if _liveTimers:
        hass: resource.DomainMapping {timer = {_k: _helperEntry(_c) for _k, _c in _liveTimers}}

mixin CounterMixin for protocol.PackageProtocol:
    """CounterMixin writes the package's `counters` to the `counter:` map."""
    _liveCounters = {_k: _c for _k, _c in config.counters or {} if _c}
    if _liveCounters:
        hass: resource.DomainMapping {counter = {_k: _helperEntry(_c) for _k, _c in _liveCounters}}

mixin ScheduleMixin for protocol.PackageProtocol:
    """ScheduleMixin writes the package's `schedules` to the `schedule:` map."""
    _liveSchedules = {_k: _c for _k, _c in config.schedules or {} if _c}
    if _liveSchedules:
        hass: resource.DomainMapping {schedule = {_k: _helperEntry(_c) for _k, _c in _liveSchedules}}
