import models.frontend
import models.resource

protocol PackageProtocol:
    """PackageProtocol provides constraints on mixins required by the package backend."""
    config: frontend.Package
    hass: resource.DomainMapping
