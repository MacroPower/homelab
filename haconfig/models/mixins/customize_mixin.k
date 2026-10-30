import models.protocol
import models.resource

mixin CustomizeMixin for protocol.PackageProtocol:
    """CustomizeMixin writes the package's `customize` map to its
    `homeassistant: customize:` block.
    """
    if config.customize:
        hass: resource.DomainMapping {homeassistant = {customize = config.customize}}

mixin ExtraConfigMixin for protocol.PackageProtocol:
    """ExtraConfigMixin writes the package's `extraConfig` keys verbatim. The
    Package checks reject a key that another mixin writes, so this union never
    merges two lists by index.
    """
    if config.extraConfig:
        hass: resource.DomainMapping {**config.extraConfig}
