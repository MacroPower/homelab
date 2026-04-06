import file

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.frontend.secret
import konfig.models.templates.networkpolicy as npt
import konfig.files

import charts.envoy_gateway.api.v1 as gatewayv1
import charts.envoy_gateway.api.v1alpha1 as gatewayv1alpha1
import charts.envoy_gateway.api.v1alpha2 as gatewayv1alpha2

import public_shared
import charts.rustdesk

_values = files.read_yaml(file.current(), "values.yaml")

_appName = "rustdesk"
_fullName = "${public_shared.tenant.name}-${_appName}"

_gwRef = {
    name = "public-gateway"
    namespace = "envoy-gateway"
}

_wsIdRoute = gatewayv1.HTTPRoute {
    metadata.name = "${_fullName}-ws-id"
    spec: {
        hostnames = ["rustdesk.jacobcolvin.com"]
        parentRefs = [{
            name = _gwRef.name
            namespace = _gwRef.namespace
            sectionName = "https"
        }]
        rules = [{
            matches = [{
                path = {
                    $type = "PathPrefix"
                    value = "/ws/id"
                }
            }]
            backendRefs = [{
                name = "rustdesk-hbbs"
                port = 21118
            }]
        }]
    }
}

_wsRelayRoute = gatewayv1.HTTPRoute {
    metadata.name = "${_fullName}-ws-relay"
    spec: {
        hostnames = ["rustdesk.jacobcolvin.com"]
        parentRefs = [{
            name = _gwRef.name
            namespace = _gwRef.namespace
            sectionName = "https"
        }]
        rules = [{
            matches = [{
                path = {
                    $type = "PathPrefix"
                    value = "/ws/relay"
                }
            }]
            backendRefs = [{
                name = "rustdesk-hbbr"
                port = 21119
            }]
        }]
    }
}

_wsIdPolicy = gatewayv1alpha1.BackendTrafficPolicy {
    metadata.name = "${_fullName}-ws-id"
    spec: {
        targetRefs = [{
            group = "gateway.networking.k8s.io"
            kind = "HTTPRoute"
            name = "${_fullName}-ws-id"
        }]
        httpUpgrade = [{
            $type = "websocket"
        }]
        timeout = {
            http = {
                connectionIdleTimeout = "360s"
                requestTimeout = "0s"
            }
        }
    }
}

_wsRelayPolicy = gatewayv1alpha1.BackendTrafficPolicy {
    metadata.name = "${_fullName}-ws-relay"
    spec: {
        targetRefs = [{
            group = "gateway.networking.k8s.io"
            kind = "HTTPRoute"
            name = "${_fullName}-ws-relay"
        }]
        httpUpgrade = [{
            $type = "websocket"
        }]
        timeout = {
            http = {
                connectionIdleTimeout = "360s"
                requestTimeout = "0s"
            }
        }
    }
}

_natTestTcpRoute = gatewayv1alpha2.TCPRoute {
    metadata.name = "${_fullName}-nat-test"
    spec: {
        parentRefs = [{
            name = _gwRef.name
            namespace = _gwRef.namespace
            sectionName = "rustdesk-nat-test"
        }]
        rules = [{
            backendRefs = [{
                name = "rustdesk-hbbs"
                port = 21115
            }]
        }]
    }
}

_idTcpRoute = gatewayv1alpha2.TCPRoute {
    metadata.name = "${_fullName}-id-tcp"
    spec: {
        parentRefs = [{
            name = _gwRef.name
            namespace = _gwRef.namespace
            sectionName = "rustdesk-id-tcp"
        }]
        rules = [{
            backendRefs = [{
                name = "rustdesk-hbbs"
                port = 21116
            }]
        }]
    }
}

_idUdpRoute = gatewayv1alpha2.UDPRoute {
    metadata.name = "${_fullName}-id-udp"
    spec: {
        parentRefs = [{
            name = _gwRef.name
            namespace = _gwRef.namespace
            sectionName = "rustdesk-id-udp"
        }]
        rules = [{
            backendRefs = [{
                name = "rustdesk-hbbs"
                port = 21116
            }]
        }]
    }
}

_relayTcpRoute = gatewayv1alpha2.TCPRoute {
    metadata.name = "${_fullName}-relay"
    spec: {
        parentRefs = [{
            name = _gwRef.name
            namespace = _gwRef.namespace
            sectionName = "rustdesk-relay"
        }]
        rules = [{
            backendRefs = [{
                name = "rustdesk-hbbr"
                port = 21117
            }]
        }]
    }
}

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
    name = _appName
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
                toFQDNs = [
                    {matchName = "rustdesk.com"}
                    {matchPattern = "*.rustdesk.com"}
                ]
                toPorts = [{
                    ports = [{
                        port = "443"
                        protocol = "TCP"
                    }]
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

    extraResources: {
        wsIdRoute = _wsIdRoute
        wsRelayRoute = _wsRelayRoute
        wsIdPolicy = _wsIdPolicy
        wsRelayPolicy = _wsRelayPolicy
        natTestTcpRoute = _natTestTcpRoute
        idTcpRoute = _idTcpRoute
        idUdpRoute = _idUdpRoute
        relayTcpRoute = _relayTcpRoute
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
