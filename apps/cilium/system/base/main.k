import file

import charts.cilium
import charts.cilium.api.v2alpha1 as ciliumv2alpha1
import cilium_shared
import konfig.models.frontend
import konfig.models.frontend.ingress
import konfig.models.utils as modelutils
import konfig.utils

_valueFile = utils.abs_path(file.current(), "values.yaml")

ciliumIngressLabels: {str:str} = {
    "cilium.io/ingress": "true"
}

unifiBGPPeering = ciliumv2alpha1.CiliumBGPPeeringPolicy {
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
                serviceSelector.matchLabels = ciliumIngressLabels
            }
        ]
    }
}

app = frontend.App {
    name = "system"
    tenantName = cilium_shared.tenant.name

    charts.cilium = cilium.Chart {
        valueFiles: [_valueFile]
    }

    ingresses.main = ingress.Ingress {
        name = "hubble-ui"
        className = "cilium"
        rules.main = {
            host.name = "hubble"
            httpPaths.main.backend.service = {
                name = "hubble-ui"
                port.name = "http"
            }
        }
    }
}
