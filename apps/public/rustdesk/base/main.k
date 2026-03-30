import file

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.frontend.secret
import konfig.models.templates.networkpolicy as npt
import konfig.files

import public_shared
import charts.rustdesk

_values = files.read_yaml(file.current(), "values.yaml")

_keypair = secret.ExternalSecret {
    name = "rustdesk-keypair"
    data: {
        RUSTDESK_KEY_PRIV = {}
        RUSTDESK_KEY_PUB = {}
    }
    target.template.data = {
        id_ed25519 = "{{ .RUSTDESK_KEY_PRIV }}"
        "id_ed25519.pub" = "{{ .RUSTDESK_KEY_PUB }}"
    }
}

app = frontend.App {
    name = "rustdesk"
    tenantName = public_shared.tenant.name
    secretStore = public_shared.shared.secretStores.default.name
    externalSecrets.keypair = _keypair

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        gatewayIngress = npt.envoyGatewayIngress
        rustdeskEgress = networkpolicy.NetworkPolicy {
            name = "rustdesk-egress"
            egress = [{
                toFQDNs = [{
                    matchPattern = "*.rustdesk.com"
                }]
                toPorts = [{
                    ports = [{
                        port = "443"
                        protocol = "TCP"
                    }]
                }]
            }]
        }
        rustdeskIngress = networkpolicy.NetworkPolicy {
            name = "rustdesk-ingress"
            ingress = [{
                fromEntities = ["all"]
                toPorts = [{
                    ports = [
                        {
                            port = "21115"
                            protocol = "TCP"
                        }
                        {
                            port = "21116"
                            protocol = "ANY"
                        }
                        {
                            port = "21117"
                            protocol = "TCP"
                        }
                        {
                            port = "21118"
                            protocol = "TCP"
                        }
                        {
                            port = "21119"
                            protocol = "TCP"
                        }
                    ]
                }]
            }]
        }
    }

    charts.rustdesk = rustdesk.Chart {
        values = _values | rustdesk.Values {
            global.nameOverride = name
            global.fullnameOverride = name
        }
    }

    routes.rustdeskWeb = gateway.Route {
        gatewayRef = public_shared.tenant.gateways.default
        services.rustdeskWeb = {
            name = "${name}-web"
            port = 21114
        }
        homepage = {
            name = "RustDesk"
            description = "Remote Desktop Server"
            group = "Apps"
            icon = "rustdesk"
        }
    }
}
