import charts.argo_cd.api.v1alpha1 as argov1alpha1
import models.frontend.common
import models.frontend.secret
import models.frontend.gateway

schema Tenant(common.Metadata):
    """
    Tenant is an abstraction of a logical group of Apps, and is responsible for
    management of higher-level resources, such as Capsule's Tenant or ArgoCD's
    AppProject. It also propagates useful metadata, which can in turn be used to
    more easily manage some resources, e.g. NetworkPolicy.
    """
    secretStores?: {str:secret.ClusterSecretStore}
    gateways?: {str:gateway.Gateway}
    oidcIssuer?: str
    destinations?: {str:argov1alpha1.ArgoprojIoV1alpha1AppProjectSpecDestinationsItems0}
