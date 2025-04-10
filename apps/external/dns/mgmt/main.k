import external_dns_base
import charts.external_dns
import konfig.utils

app = external_dns_base.app | {
    externalSecrets: {
        cloudflareCreds = external_dns_base.cloudflareCreds
        unifiCreds = external_dns_base.unifiCreds
    }
    charts: {
        external_dns_unifi = external_dns.Chart {
            values: external_dns_base.unifiValues | {
                extraArgs = [
                    "--crd-source-apiversion=externaldns.k8s.io/v1alpha1"
                    "--crd-source-kind=DNSEndpoint"
                ]
            }
        }
    }
}
