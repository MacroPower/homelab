import file

import cluster
import cilium_system_base
import charts.cilium.api.v2alpha1 as ciliumv2alpha1
import konfig.utils

_valueFile = utils.abs_path(file.current(), "values.yaml")

app = cilium_system_base.app | {
    domainName = cluster.DOMAIN_NAME

    charts.cilium.valueFiles += [_valueFile]

    extraResources.bgpPeering = cilium_system_base.unifiBGPPeering
    extraResources.ipPool = ciliumv2alpha1.CiliumLoadBalancerIPPool {
        metadata: {
            name = "cilium-ingress"
        }
        spec: {
            blocks = [
                {
                    cidr = "10.10.30.0/24"
                }
                {
                    cidr = "fc42:0:0:a::10:0/108"
                }
            ]
            allowFirstLastIPs = "No"
            serviceSelector.matchLabels = cilium_system_base.ciliumIngressLabels
        }
    }
}
