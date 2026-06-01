import file

import konfig.files
import konfig.objects

import cluster
import cilium_system_base
import charts.cilium.api.v2 as ciliumv2
import charts.cilium.api.v2alpha1 as ciliumv2alpha1

_baseValues = cilium_system_base.app.charts.cilium.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe Cilium: relaxed values, and drop the hubble-ui Ingress the
# bare-metal overlays add (no ingress controller exists here).
app = cilium_system_base.app | {
    domainName = cluster.DOMAIN_NAME

    charts.cilium.values = _values

    ingresses = {}

    # LoadBalancer support without BGP. Prod advertises VIPs to the UniFi router
    # over BGP; there is no router on the Docker bridge, so instead hand out VIPs
    # from the bridge subnet (10.5.0.0/24, node at .2) and announce them over
    # L2/ARP. The host is the bridge gateway (10.5.0.1) on the same L2 segment, so
    # it resolves the VIP to the node's MAC and reaches the Service directly -- no
    # router and no route. The range stops at .250 to stay clear of the /24
    # broadcast (.255). No serviceSelector: every LoadBalancer Service is eligible.
    extraResources.lbPool = ciliumv2.CiliumLoadBalancerIPPool {
        metadata.name = "local"
        spec.blocks = [
            {
                start = "10.5.0.240"
                stop = "10.5.0.250"
            }
        ]
    }
    extraResources.l2Policy = ciliumv2alpha1.CiliumL2AnnouncementPolicy {
        metadata.name = "local"
        spec = {
            loadBalancerIPs = True
            interfaces = ["^eth0$"]
        }
    }
}
