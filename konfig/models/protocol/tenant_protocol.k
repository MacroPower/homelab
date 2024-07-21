import models.frontend.tenant
import models.resource

protocol TenantProtocol:
    """TenantProtocol provides constraints on mixins required by the tenant backend."""
    config: tenant.Tenant
    kubernetes: resource.ResourceMapping
