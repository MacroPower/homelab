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

schema App(common.Metadata):
    """Abstraction of Namespace scoped Application configuration.

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
    namespace: str, default is Undefined, optional.
        Namespace is the App's destination namespace. Generally, it should be left set to the default value, which will
        generate an appropriate namespace based on the tenantName and name.
    environment: str, default is Undefined, optional.
        Environment is the App's destination environment.
    charts: [chart.Chart], default is Undefined, optional.
        Charts is a list of Chart.
    configMaps: [configmap.ConfigMap], default is Undefined, optional.
        ConfigMaps is a list of ConfigMap.
    secrets: [secret.Secret], default is Undefined, optional.
        Secrets is a list of Secret.
    services: [service.Service], default is Undefined, optional.
        Services is a list of Service.
    ingresses: [ingress.Ingress], default is Undefined, optional.
        Ingresses is a list of Ingress which is collection of rules that allow inbound connections to reach the endpoints defined by a backend.
    serviceAccounts: [sa.ServiceAccount], default is Undefined, optional.
        ServiceAccounts a list of ServiceAccount.
    networkPolicies: [networkpolicy.NetworkPolicy], default is Undefined, optional.
        NetworkPolicies is a list of NetworkPolicy.
    extraResources: {str:{str:}}, default is Undefined, optional.
        Extra resources used to output the final result.

    Examples
    --------
    import models.frontend

    app: frontend.App {
        name = "foobar"
    }
    """
    tenantName?: str = "default"
    fullName?: str = "{}-{}".format(tenantName, name)
    namespace?: str = "{}-{}".format(tenantName, name)
    environment?: str
    domainName?: str
    secretStore?: str

    charts?: {str:helm.Chart}
    configMaps?: {str:configmap.ConfigMap}
    secrets?: {str:secret.Secret}
    services?: {str:service.Service}
    ingresses?: {str:ingress.Ingress}
    serviceAccounts?: {str:sa.ServiceAccount}
    roles?: {str:rbac.Role}
    clusterRoles?: {str:rbac.ClusterRole}
    roleBindings?: {str:rbac.RoleBinding}
    clusterRoleBindings?: {str:rbac.ClusterRoleBinding}
    networkPolicies?: {str:networkpolicy.NetworkPolicy}
    namespaceSecretStores?: {str:secret.NamespaceSecretStore}
    secretStores?: {str:secret.SecretStore}
    externalSecrets?: {str:secret.ExternalSecret}
    postgresDatabases?: {str:storage.PostgresDatabase}
    grafanaDashboards?: {str:grafana.GrafanaDashboard}

    extraResources?: {str:} = {}
