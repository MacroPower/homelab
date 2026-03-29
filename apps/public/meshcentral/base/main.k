import file
import json

import konfig.models.frontend
import konfig.models.frontend.configmap
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt
import konfig.files

import public_shared
import charts.meshcentral

_values = files.read_yaml(file.current(), "values.yaml")

_meshcentralPort = 4430

meshcentralConfig = files.read_yaml(file.current(), "config/config.yaml") | {
    settings.port = _meshcentralPort
}

app = frontend.App {
    name = "meshcentral"
    tenantName = public_shared.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        codeSigningEgress = networkpolicy.NetworkPolicy {
            name = "code-signing-egress"
            egress = [{
                toFQDNs = [{matchName = "timestamp.comodoca.com"}]
                toPorts = [{
                    ports = [{port = "80", protocol = "TCP"}]
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

    configMaps.meshcentralConfig = configmap.ConfigMap {
        name = "meshcentral-config"
        data: {
            "config.json" = json.encode(meshcentralConfig)
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
