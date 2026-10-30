import models.protocol
import models.resource

mixin ScriptMixin for protocol.PackageProtocol:
    """ScriptMixin writes the package's scripts to the `script:` map. HA merges
    the map across packages, so each key is the object id unchanged.
    """
    _liveScripts = {_k: _c for _k, _c in config.scripts or {} if _c}
    if _liveScripts:
        hass: resource.DomainMapping {script = {_k: _scriptBuilder(_c) for _k, _c in _liveScripts}}

# HA's package merge skips an empty mapping below the domain key without a
# message. A parameterless selector such as `selector.boolean = {}` therefore
# reaches HA as `selector: {}`, which disables the script, and a field written
# as `{}` disappears. The builders emit such a selector as `null` and give such
# a field HA's default `required: false`.
#
# The lambdas' names carry the `_sb` and `_sf` prefixes, because a name inside
# a lambda's comprehension resolves to a same-named attribute of the calling
# schema first.
_scriptBuilder = lambda _sbScript: any -> any {
    _sbFields = {_sbK: _scriptFieldBuilder(_sbF) for _sbK, _sbF in _sbScript.fields or {} if _sbF}
    _sbScript | {fields = _sbFields} if _sbScript.fields else _sbScript
}

_scriptFieldBuilder = lambda _sfField: any -> any {
    _sfSet = [_sfK for _sfK, _sfV in _sfField if _sfV is not Undefined]
    _sfSelector = {_sfT: None if _sfV == {} else _sfV for _sfT, _sfV in _sfField.selector or {}}
    _sfOut = _sfField | {selector = _sfSelector} if _sfField.selector else _sfField
    _sfOut if _sfSet else _sfOut | {required = False}
}
