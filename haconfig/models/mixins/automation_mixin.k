import models.frontend.common
import models.protocol
import models.resource

mixin AutomationMixin for protocol.PackageProtocol:
    """AutomationMixin writes the package's automations to the `automation:` list.
    Each automation gets `id = <package>.<key>` and `alias = humanize(key)`
    unless it sets them.
    """
    # An overlay deletion (`= Undefined`) still iterates, so filter before the
    # guard. Without the filter, deleting the last automation emits
    # `automation: []`.
    _liveAutomations = {_k: _c for _k, _c in config.automations or {} if _c}
    if _liveAutomations:
        hass: resource.DomainMapping {
            automation = [_c | {
                id = _c.id or "{}.{}".format(config.name, _k)
                alias = _c.alias or common.humanize(_k)
            } for _k, _c in _liveAutomations]
        }
