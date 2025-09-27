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
    extraResources.envoyClusterGatewayCertificate = certmanagerv1.Certificate {
        metadata.name = "cluster-wildcard"
        spec: {
            dnsNames = [
                domainName
                "*.${domainName}"
            ]
            secretName = "cluster-wildcard"
            issuerRef: {
                kind = "ClusterIssuer"
                name = "cloudflare-macro-network-issuer"
            }
        }
    }
}
