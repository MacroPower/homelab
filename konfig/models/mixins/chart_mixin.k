import argo_cd.v1alpha1 as argov1alpha1
import models.utils
import models.resource
import models.protocol

mixin ChartMixin for protocol.AppProtocol:
    if config.charts:
        kubernetes: resource.ResourceMapping {
            Chart = [argov1alpha1.Application {
                metadata: utils.AppMetadataBuilder(_c)
                spec: {
                    project = config.tenantName
                    source: {
                        chart = _c.name
                        repoURL = _c.repoURL
                        targetRevision = _c.targetRevision
                        helm: {
                            if typeof(_c.values) == "str":
                                values = _c.values
                            else:
                                valuesObject = _c.values
                        }
                    }
                    destination: {
                        name = config.environment
                        namespace = config.namespace
                    }
                    syncPolicy: {
                        automated: {
                            prune = _c.prune
                            selfHeal = _c.selfHeal
                        }
                        syncOptions: [
                            "ServerSideApply=true",
                        ]
                    }
                }
            } for _i, _c in config.charts]
        }
