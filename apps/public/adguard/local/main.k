import file
import yaml

import konfig.models.frontend.configmap
import konfig.files
import konfig.objects

import public_adguard_base
import cluster
import charts.adguard
import charts.cert_manager.api.v1 as certmanagerv1

_baseValues = public_adguard_base.app.charts.adguard.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

_adguardConfig = public_adguard_base.adguardConfig

# Docker-safe local overlay for adguard. Differences from main/main.k:
#  - controllers.app.replicas 2 -> 1 (single tald node, via values.yaml).
#  - The DNS LoadBalancer keeps type:LoadBalancer but DROPS the hardcoded prod VIP
#    annotation (lbipam.cilium.io/ips: 10.10.40.20 is not in the local pool); LB-IPAM
#    auto-assigns from the bridge subnet so the Service is still reachable over L2/ARP.
#  - The dns Certificate is signed by the SelfSigned ClusterIssuer that
#    apps/external/certs/local stands up, instead of the offline Cloudflare DNS-01
#    ClusterIssuer, so the adguard-dns-cert Secret is created and the pod can mount it.
#  - The adguard-oidc-client ExternalSecret keys are redirected to "dummy" so the
#    fake secret store answers them offline.
app = public_adguard_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.adguard.values = _values | adguard.Values {}

    externalSecrets.adguardOIDCClient.data: {
        "client-id" = {
            remoteRef.key = "dummy"
        }
        "client-secret" = {
            remoteRef.key = "dummy"
        }
    }

    configMaps.adguardConfig = configmap.ConfigMap {
        name = "adguard-config"
        data: {
            "AdGuardHome.yaml" = yaml.encode(_adguardConfig | {
                tls.server_name = "dns.${domainName}"
                dns.upstream_dns = [
                    "https://us-nyc-dns-601.mullvad.net/dns-query"
                    "https://us-dal-dns-001.mullvad.net/dns-query"
                    "[/macro.network/]tcp://10.10.0.1"
                    "[/jacobcolvin.com/]tcp://10.10.0.1"
                    "[/raw.githubusercontent.com/]tcp://10.10.0.1"
                ]
                dns.bootstrap_dns = ["10.10.0.1"]
                dns.fallback_dns = ["10.10.0.1"]
                dns.local_ptr_upstreams = ["10.10.0.1"]
            })
        }
    }

    extraResources.dnsCert = certmanagerv1.Certificate {
        metadata.name = "adguard-dns"
        spec: {
            dnsNames = ["dns.${domainName}"]
            secretName = "adguard-dns-cert"
            issuerRef: {
                kind = "ClusterIssuer"
                name = "selfsigned-issuer"
            }
        }
    }
}
