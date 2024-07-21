import k8s.api.core.v1
import models.metadata
import models.utils
import models.resource
import models.protocol

mixin ServiceMixin for protocol.AppProtocol:
    if config.services:
        kubernetes: resource.ResourceMapping {
            Service = [v1.Service {
                metadata: utils.MetadataBuilder(_s) | {
                    name = _s?.name or (workloadName if len(config.services) == 1 else "{}{}{}".format(metadata.__META_APP_NAME, metadata.__META_ENV_TYPE_NAME, _i))
                }
                spec: {
                    clusterIP = _s?.clusterIP if _s?.type in ["ClusterIP", "NodePort", "LoadBalancer", None, Undefined] else Undefined
                    externalIPs = _s?.externalIPs
                    externalName = _s?.externalName if _s?.type == "ExternalName" else Undefined
                    externalTrafficPolicy = _s?.externalTrafficPolicy
                    healthCheckNodePort = _s?.healthCheckNodePort if _s?.type == "LoadBalancer" and _s?.externalTrafficPolicy == "Local" else Undefined
                    ipFamilyPolicy = _s?.ipFamilyPolicy
                    loadBalancerIP = _s?.loadBalancerIP if _s?.type == "LoadBalancer" else Undefined
                    loadBalancerSourceRanges = _s?.loadBalancerSourceRanges
                    ports = _s?.ports
                    publishNotReadyAddresses = _s?.publishNotReadyAddresses
                    selector = _s?.selector
                    sessionAffinity = _s?.sessionAffinity
                    sessionAffinityConfig = _s?.sessionAffinityConfig if _s?.sessionAffinity == "ClientIP" else Undefined
                    type = _s?.type
                }
            } for _i, _s in config.services]
        }
