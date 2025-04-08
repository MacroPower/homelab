import charts.cilium.api.v2 as ciliumv2
import models.utils
import models.resource
import models.protocol

mixin NetworkPolicyMixin for protocol.AppProtocol:
    if config.networkPolicies:
        kubernetes: resource.ResourceMapping {
            NetworkPolicy = [ciliumv2.CiliumNetworkPolicy {
                metadata: utils.MetadataBuilder(_n)
                spec: {
                    endpointSelector: _n.endpointSelector
                    ingress: _n.ingress
                    egress: _n.egress
                }
            } for _i, _n in config.networkPolicies]
        }
