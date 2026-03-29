import file
import json

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.frontend.secret
import konfig.models.templates.networkpolicy as npt
import konfig.files

import public_shared
import charts.meshcentral

_values = files.read_yaml(file.current(), "values.yaml")

_meshcentralPort = 4430

meshcentralConfig = files.read_yaml(file.current(), "config/config.yaml") | {
    settings.port = _meshcentralPort
}

_certFiles = [
    "root-cert-public.crt"
    "root-cert-private.key"
    "agentserver-cert-public.crt"
    "agentserver-cert-private.key"
    "webserver-cert-public.crt"
    "webserver-cert-private.key"
    "mpsserver-cert-public.crt"
    "mpsserver-cert-private.key"
    "codesign-cert-public.crt"
    "codesign-cert-private.key"
]

_certDopplerKey = lambda name: str -> str {
    "MESHCENTRAL_" + name.replace("-", "_").replace(".", "_").upper()
}

_certs = secret.ExternalSecret {
    name = "meshcentral-certs"
    data: {_certDopplerKey(f) = {} for f in _certFiles}
    target.template.data = {"${f}" = "{{ .${_certDopplerKey(f)} }}" for f in _certFiles}
}

app = frontend.App {
    name = "meshcentral"
    tenantName = public_shared.tenant.name
    secretStore = public_shared.shared.secretStores.default.name
    externalSecrets.meshcentralCerts = _certs

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        icmpV4Egress = networkpolicy.NetworkPolicy {
            name = "icmp-v4-egress"
            egress = [{
                toEntities = ["all"]
                icmps = [{
                    fields = [
                        {family = "IPv4", type = "EchoRequest"}
                        {family = "IPv4", type = "EchoReply"}
                        {family = "IPv4", type = "DestinationUnreachable"}
                        {family = "IPv4", type = "TimeExceeded"}
                    ]
                }]
            }]
        }
        codeSigningEgress = networkpolicy.NetworkPolicy {
            name = "code-signing-egress"
            egress = [{
                toFQDNs = [{matchName = "timestamp.comodoca.com"}]
                toPorts = [{
                    ports = [{port = "80", protocol = "TCP"}]
                }]
            }]
        }
        auth0Egress = networkpolicy.NetworkPolicy {
            name = "auth0-egress"
            egress = [{
                toFQDNs = [{matchName = "auth.jacobcolvin.com"}]
                toPorts = [{
                    ports = [{port = "443", protocol = "TCP"}]
                }]
            }]
        }
        npmRegistryEgress = networkpolicy.NetworkPolicy {
            name = "npm-registry-egress"
            egress = [{
                toFQDNs = [{matchName = "registry.npmjs.org"}]
                toPorts = [{
                    ports = [{port = "443", protocol = "TCP"}]
                }]
            }]
        }
        gatewayIngress = npt.envoyGatewayIngress
    }

    charts.meshcentral = meshcentral.Chart {
        values = _values | meshcentral.Values {
            global.nameOverride = name
            global.fullnameOverride = name
        }
    }

    routes.meshcentralWeb = gateway.Route {
        gatewayRef = public_shared.tenant.gateways.default
        services.meshcentralWeb = {
            name = name
            port = _meshcentralPort
        }
        homepage = {
            name = "MeshCentral"
            description = "Remote Desktop Management"
            group = "Apps"
            icon = "meshcentral"
        }
    }
}
