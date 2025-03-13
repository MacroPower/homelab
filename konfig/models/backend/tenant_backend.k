import charts.argo_cd.crds as argov1alpha1
import models.frontend
import models.mixins
import models.resource
import models.utils

schema TenantBackend[inputConfig: frontend.Tenant]:
    """
    TenantBackend converts the user-written front-end model `Tenant` into a
    collection of k8s resources and places the resource collection into
    the `k8s` attribute.
    """
    mixin [
        # Resource builder mixin
        mixins.ClusterSecretStoreMixin
    ]

    # Store the input config parameter, ensure it can be seen in protocol and mixin.
    config: frontend.Tenant = inputConfig

    _argoAppProject: argov1alpha1.AppProject {
        metadata = utils.MetadataBuilder(config)
        spec: {
            sourceNamespaces: ["{}-*".format(config.name)]
            sourceRepos: ["*"]
            destinations: [{
                namespace = "{}-*".format(config.name)
                server = "*"
            }]
            clusterResourceWhitelist: [{
                group = "*"
                kind = "*"
            }]
            namespaceResourceWhitelist: [{
                group = "*"
                kind = "*"
            }]
        }
    }

    if config.destinations:
        _argoAppProject.spec.destinations += [{
            namespace = _c.namespace
            server = _c?.server or "*"
        } for _k, _c in config.destinations]

    kubernetes: resource.ResourceMapping = {
        if _argoAppProject:
            "${typeof(_argoAppProject)}" = [_argoAppProject]
    }
