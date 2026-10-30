import models.protocol
import models.resource

mixin TemplateMixin for protocol.PackageProtocol:
    """TemplateMixin writes the package's template sections to the `template:`
    list. Each entity gets `unique_id = <package>.<key>` and
    `default_entity_id = <domain>.<key>` unless it sets them, so the map key is
    the single source of a template entity's identity. A section without a
    live entity creates nothing in HA, so the mixin drops it.
    """
    # An overlay deletion (`= Undefined`) still iterates, so filter each
    # section's entities before the guard. Without the filter, deleting the
    # last entity of a section emits `- sensor: []`.
    _liveTemplates = [_c for _, _c in config.templates or {} if _c and _templateEntityMaps(_c)]
    if _liveTemplates:
        hass: resource.DomainMapping {
            template = [_templateSectionBuilder(config.name, _c) for _c in _liveTemplates]
        }

# The lambdas' parameters and locals carry the `_tm`, `_te` and `_ts`
# prefixes, because a name inside a lambda's comprehension resolves to a
# same-named attribute of the calling schema first.

# _templateEntityMaps returns the section's live entities keyed by HA domain,
# with the typed domains first. It drops deleted entities and empty domains.
_templateEntityMaps = lambda _tmSection: any -> {str:{str:any}} {
    _tmTyped = {
        sensor = _tmSection.sensors
        binary_sensor = _tmSection.binarySensors
        switch = _tmSection.switches
        button = _tmSection.buttons
        number = _tmSection.numbers
        select = _tmSection.selects
    }
    _tmAll = {**_tmTyped, **(_tmSection.entities or {})}
    _tmLive = {_tmD: {_tmK: _tmE for _tmK, _tmE in _tmEs or {} if _tmE} for _tmD, _tmEs in _tmAll}
    {_tmD: _tmEs for _tmD, _tmEs in _tmLive if _tmEs}
}

_templateEntitiesBuilder = lambda _tePkg: str, _teDomain: str, _teEntities: {str:any} -> [any] {
    [_teE | {
        unique_id = _teE.unique_id or "{}.{}".format(_tePkg, _teK)
        default_entity_id = _teE.default_entity_id or "{}.{}".format(_teDomain, _teK)
    } for _teK, _teE in _teEntities]
}

_templateSectionBuilder = lambda _tsPkg: str, _tsSection: any -> {str:} {
    {
        if _tsSection.triggers: triggers = _tsSection.triggers
        if _tsSection.conditions: conditions = _tsSection.conditions
        if _tsSection.actions: actions = _tsSection.actions
        if _tsSection.variables: variables = _tsSection.variables
        **{_tsD: _templateEntitiesBuilder(_tsPkg, _tsD, _tsEs) for _tsD, _tsEs in _templateEntityMaps(_tsSection)}
    }
}
