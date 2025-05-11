import models.frontend.configmap
import models.frontend.secret
import models.frontend.service
import models.frontend.serviceaccount as sa
import models.frontend.ingress
import models.frontend.rbac
import models.frontend.networkpolicy
import models.frontend.storage
import models.frontend.grafana
import models.frontend.common

import helm

schema SharedApp(common.Metadata):
    """Abstraction of Cluster scoped Application configuration.

    Attributes
    ----------
    name: str, required.
        The name of the Application.
    labels: {str:str}, default is Undefined, optional.
        Labels is a map of string keys and values that can be used to organize and categorize (scope and select) objects.
        More info: http://kubernetes.io/docs/user-guide/labels
    annotations: {str:str}, default is Undefined, optional
        Annotations is an unstructured key value map stored with a resource that may be set by external tools to store and retrieve arbitrary metadata.
        More info: http://kubernetes.io/docs/user-guide/annotations
    tenantName: str, default is Undefined, optional.
        TenantName is the name of the Tenant which the App should belong to.

    Examples
    --------
    import models.frontend

    app = frontend.SharedApp {
        name = "foobar"
    }
    """
    tenantName?: str = "default"

    clusterRoles?: {str:rbac.ClusterRole}
    clusterRoleBindings?: {str:rbac.ClusterRoleBinding}
    secretStores?: {str:secret.SecretStore}
