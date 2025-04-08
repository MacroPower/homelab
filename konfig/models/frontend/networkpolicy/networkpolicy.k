import models.frontend.common
import charts.cilium.api.v2 as ciliumv2

schema NetworkPolicy(common.Metadata):
    """
    NetworkPolicy defines rules for network traffic to and from the selected
    endpoints.

    Attributes
    ----------
    endpointSelector: ciliumv2.CiliumIoV2CiliumNetworkPolicySpecEndpointSelector, default is {}, optional
        Selects all endpoints which should be subject to this rule. If not set, the rule applies to all endpoints.
    egress: [ciliumv2.CiliumIoV2CiliumNetworkPolicySpecEgressItems0], default is [{}], optional
        List of rules to be applied at egress.
    ingress: [ciliumv2.CiliumIoV2CiliumNetworkPolicySpecIngressItems0], default is [{}], optional
        List of rules to be applied at ingress.
    """
    endpointSelector?: ciliumv2.CiliumIoV2CiliumNetworkPolicySpecEndpointSelector = {}
    egress?: [ciliumv2.CiliumIoV2CiliumNetworkPolicySpecEgressItems0]
    ingress?: [ciliumv2.CiliumIoV2CiliumNetworkPolicySpecIngressItems0]
