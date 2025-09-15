import file
import yaml

import konfig.models.frontend
import konfig.models.frontend.configmap
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.frontend.secret
import konfig.models.templates.networkpolicy as npt
import konfig.files

import public
import charts.adguard

_values = files.read_yaml(file.current(), "values.yaml")

adguardConfig = files.read_yaml(file.current(), "config/AdGuardHome.yaml")

_adguardOIDCClient = secret.ExternalSecret {
    name = "adguard-oidc-client"
    data: {
        "client-id" = {
            remoteRef.key = "LAB_ADMIN_AUTH0_CLIENT_ID"
        }
        "client-secret" = {
            remoteRef.key = "LAB_ADMIN_AUTH0_CLIENT_SECRET"
        }
    }
}

_adguardWebPort = 3000

app = frontend.App {
    name = "adguard"
    tenantName = public.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        gatewayIngress = npt.envoyGatewayIngress
        dnsIngress = networkpolicy.NetworkPolicy {
            name = "dns-ingress"
            ingress = [{
                fromEntities = ["all"]
                toPorts = [{
                    ports = [
                        {
                            port = "53"
                            protocol = "ANY"
                        }
                        {
                            port = "80"
                            protocol = "ANY"
                        }
                        {
                            port = "443"
                            protocol = "ANY"
                        }
                        {
                            port = "853"
                            protocol = "ANY"
                        }
                    ]
                }]
            }]
        }
        unifiDNSEgress = networkpolicy.NetworkPolicy {
            name = "unifi-dns-egress"
            egress = [{
                toCIDR = ["10.10.0.1/32"]
                toPorts = [{
                    ports = [{
                        port = "53"
                        protocol = "ANY"
                    }]
                    rules.dns = [{
                        matchPattern = "*"
                    }]
                }]
            }]
        }
        mullvadDOHEgress = networkpolicy.NetworkPolicy {
            name = "mullvad-doh-egress"
            egress = [{
                toFQDNs = [{
                    matchPattern = "dns.mullvad.net"
                }]
                toPorts = [{
                    ports = [{
                        port = "443"
                        protocol = "TCP"
                    }]
                }]
            }]
        }
        githubEgress = networkpolicy.NetworkPolicy {
            name = "github-egress"
            egress = [{
                toFQDNs = [{
                    matchPattern = "raw.githubusercontent.com"
                }]
                toPorts = [{
                    ports = [{
                        port = "443"
                        protocol = "TCP"
                    }]
                }]
            }]
        }
    }

    secretStore = public.shared.secretStores.default.name
    externalSecrets: {
        adguardOIDCClient = _adguardOIDCClient
    }

    charts.adguard = adguard.Chart {
        values = _values | adguard.Values {
            global.nameOverride = name
            global.fullnameOverride = name
            service.app.ports.http.port = _adguardWebPort
        }
    }

    configMaps.adguardConfig = configmap.ConfigMap {
        name = "adguard-config"
        data: {
            "AdGuardHome.yaml" = yaml.encode(adguardConfig)
        }
    }

    routes.adguardWeb = gateway.Route {
        gatewayRef = public.tenant.gateways.default
        services.adguardWeb = {
            name = "${name}-app"
            port = _adguardWebPort
        }
        security = gateway.SecurityPolicy {
            oidcClientRef = _adguardOIDCClient.name
            oidcIssuer = public.tenant.oidcIssuer
        }
    }
}
