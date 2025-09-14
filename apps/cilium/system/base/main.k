import file

import konfig.models.frontend
import konfig.models.frontend.ingress
import konfig.models.utils as modelutils
import konfig.files

import cilium_shared
import charts.cilium
import charts.cilium.api.v2 as ciliumv2

_values = files.read_yaml(file.current(), "values.yaml")

ciliumIngressLabels: {str:str} = {
    "cilium.io/ingress": "true"
}

unifiBGPPeer = ciliumv2.CiliumBGPPeerConfig {
    metadata: modelutils.AppMetadataBuilder({
        name = "unifi"
    }, modelutils.ArgoCDOptions {
        sync.SkipDryRunOnMissingResource = True
    })
    spec: {
        ebgpMultihop = 1
        families = [
            {
                afi = "ipv4"
                safi = "unicast"
                advertisements.matchLabels = ciliumIngressLabels
            }
        ]
    }
}

unifiBGPPeering = ciliumv2.CiliumBGPClusterConfig {
    metadata: modelutils.AppMetadataBuilder({
        name = "unifi"
    }, modelutils.ArgoCDOptions {
        sync.SkipDryRunOnMissingResource = True
    })
    spec: {
        nodeSelector.matchLabels = {
            "bgp.kube.macro.network/peer-group" = "main"
        }
        bgpInstances = [
            {
                name = "unifi"
                localASN = 64512
                peers = [
                    {
                        name = "unifi-main"
                        peerAddress = "10.1.0.1"
                        peerASN = 64512
                        peerConfigRef.name = unifiBGPPeer.metadata.name
                    }
                ]
            }
        ]
    }
}

ingressBGPAdvertisement = ciliumv2.CiliumBGPAdvertisement {
    metadata: modelutils.AppMetadataBuilder({
        name = "cilium-ingress"
        labels = ciliumIngressLabels
    }, modelutils.ArgoCDOptions {
        sync.SkipDryRunOnMissingResource = True
    })
    spec: {
        advertisements = [
            {
                advertisementType = "Service"
                service.addresses = ["LoadBalancerIP"]
                selector.matchLabels = ciliumIngressLabels
            }
            {
                advertisementType = "Service"
                service.addresses = ["LoadBalancerIP"]
                selector.matchLabels = {
                    "app.kubernetes.io/name" = "envoy"
                    "app.kubernetes.io/component" = "proxy"
                }
            }
        ]
    }
}

app = frontend.App {
    name = "system"
    tenantName = cilium_shared.tenant.name

    charts.cilium = cilium.Chart {
        values: _values | cilium.Values {}
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
