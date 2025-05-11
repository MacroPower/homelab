import file

import charts.cilium
import charts.cilium.api.v2alpha1 as ciliumv2alpha1
import cilium_shared
import konfig.models.frontend
import konfig.models.utils as modelutils
import konfig.utils

_valueFile = utils.abs_path(file.current(), "values.yaml")

app = frontend.App {
    name = "system"
    tenantName = cilium_shared.tenant.name

    charts.cilium = cilium.Chart {
        valueFiles: [_valueFile]
    }

    extraResources.bgpPeering = ciliumv2alpha1.CiliumBGPPeeringPolicy {
        metadata: modelutils.AppMetadataBuilder({
            name = "cilium-ingress"
        }, modelutils.ArgoCDOptions {
            sync.SkipDryRunOnMissingResource = True
        })
        spec: {
            # nodeSelector.matchLabels = {
            #     "bgp.kube.macro.network/peer-group" = "main"
            # }
            virtualRouters = [
                {
                    localASN = 64512
                    exportPodCIDR = False
                    neighbors = [
                        {
                            peerAddress = "10.1.0.1/32"
                            peerASN = 64512
                            eBGPMultihopTTL = 1
                        }
                    ]
                    serviceSelector.matchLabels = {
                        "cilium.io/ingress": "true"
                    }
                }
            ]
        }
    }

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
            serviceSelector.matchLabels = {
                "cilium.io/ingress": "true"
            }
        }
    }
}
