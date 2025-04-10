import cluster
import charts.cert_manager
import charts.cert_manager.api.v1 as certmanagerv1
import external_certs_base

_baseValues = external_certs_base.app.charts.cert_manager.values

app = external_certs_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.cert_manager.values = _baseValues | cert_manager.Values {
        replicaCount = 2
    }
    extraResources.cloudflareClusterIngress = certmanagerv1.Certificate {
        metadata.name = "cluster-ingress"
        spec: {
            dnsNames = ["*.${domainName}"]
            secretName = "cluster-ingress"
            issuerRef: {
                kind = "ClusterIssuer"
                name = "cloudflare-issuer"
            }
        }
    }
}
