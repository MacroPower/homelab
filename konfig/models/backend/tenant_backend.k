import argo_cd.v1alpha1 as argov1alpha1
import models.frontend
#import models.mixins
import models.utils
import models.resource

schema TenantBackend[inputConfig: frontend.Tenant]:
    """
    TenantBackend converts the user-written front-end model `Tenant` into a
    collection of k8s resources and places the resource collection into
    the `k8s` attribute.
    """
    # mixin [
    #     # Resource builder mixin
    #     mixins.NetworkPolicyMixin,
    # ]

    # Store the input config parameter, ensure it can be seen in protocol and mixin.
    config: frontend.Tenant = inputConfig

    _argoAppProject = argov1alpha1.AppProject {
        metadata: utils.MetadataBuilder(config)
        spec: {
            sourceNamespaces: ["{}-*".format(config.name)]
            sourceRepos: ["*"]
            destinations: [
                {
                    namespace: "{}-*".format(config.name)
                    server: "*"
                }
            ]
            clusterResourceWhitelist: [
                {
                    group: "*"
                    kind: "*"
                }
            ]
            namespaceResourceWhitelist: [
                {
                    group: "*"
                    kind: "*"
                }
            ]
        }
    }

    kubernetes: resource.ResourceMapping = {
        if _argoAppProject:
            "${typeof(_argoAppProject)}" = [_argoAppProject]
    }
