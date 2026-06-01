import file

import konfig.files
import konfig.objects

import cluster
import envoy_gateway_base
import charts.envoy_gateway
import charts.cert_manager.api.v1 as certmanagerv1

_baseValues = envoy_gateway_base.app.charts.envoy_gateway.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = envoy_gateway_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.envoy_gateway.values = _values | envoy_gateway.Values {}

    # Single node: one data-plane replica (base runs 2). The LoadBalancer Service
    # is kept as-is -- apps/cilium/system/local hands it a VIP from the bridge
    # subnet and announces it over L2/ARP, so it is reachable from the host. The
    # BGP peer-group label is inert locally (the L2 policy selects all Services).
    extraResources.proxy.spec.provider.kubernetes.envoyDeployment.replicas = 1

    # ACME / Cloudflare DNS-01 issuance can't work offline, so sign the gateway
    # wildcard certs with the SelfSigned ClusterIssuer that apps/external/certs/local
    # stands up. This populates the cluster-wildcard / public-wildcard Secrets the
    # Gateway HTTPS listeners reference.
    extraResources.envoyPublicGatewayCertificate.spec.issuerRef = {
        kind = "ClusterIssuer"
        name = "selfsigned-issuer"
    }

    extraResources.envoyClusterGatewayCertificate = certmanagerv1.Certificate {
        metadata.name = "cluster-wildcard"
        spec: {
            dnsNames = [
                cluster.DOMAIN_NAME
                "*.${cluster.DOMAIN_NAME}"
            ]
            secretName = "cluster-wildcard"
            issuerRef: {
                kind = "ClusterIssuer"
                name = "selfsigned-issuer"
            }
        }
    }
}
