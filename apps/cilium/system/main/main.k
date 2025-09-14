import file

import konfig.files
import konfig.objects

import cluster
import cilium_system_base
import charts.cilium.api.v2 as ciliumv2

_baseValues = cilium_system_base.app.charts.cilium.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = cilium_system_base.app | {
    domainName = cluster.DOMAIN_NAME

    charts.cilium.values = _values

    extraResources.bgpPeer = cilium_system_base.unifiBGPPeer
    extraResources.bgpPeering = cilium_system_base.unifiBGPPeering
    extraResources.bgpAdvertisement = cilium_system_base.ingressBGPAdvertisement
    extraResources.ipPool = ciliumv2.CiliumLoadBalancerIPPool {
        metadata: {
            name = "cilium-ingress"
        }
        spec: {
            blocks = [
                {
                    cidr = "10.10.40.0/28"
                }
                {
                    cidr = "fc42:0:0:a::4010:0/108"
                }
            ]
            allowFirstLastIPs = "No"
            serviceSelector.matchLabels = cilium_system_base.ciliumIngressLabels
        }
    }
    extraResources.envoyIPPool = ciliumv2.CiliumLoadBalancerIPPool {
        metadata: {
            name = "envoy-gateway"
        }
        spec: {
            blocks = [
                {
                    cidr = "10.10.40.16/28"
                }
                {
                    cidr = "fc42:0:0:a::4020:0/108"
                }
            ]
            allowFirstLastIPs = "Yes"
            serviceSelector.matchLabels = {
                "app.kubernetes.io/name" = "envoy"
                "app.kubernetes.io/component" = "proxy"
            }
        }
    }
}
