import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.models.templates.networkpolicy as npt
import konfig.files

import truenas_shared
import charts.restic

_values = files.read_yaml(file.current(), "values.yaml")

_htpasswd = secret.ExternalSecret {
    name = "restic-credentials"
    data: {
        RESTIC_USERNAME = {}
        RESTIC_PASSWORD = {}
    }
    target.template.data = {
        ".htpasswd" = "{{ .RESTIC_USERNAME }}:{{ .RESTIC_PASSWORD | bcrypt }}"
    }
}

app = frontend.App {
    name = "restic"
    tenantName = truenas_shared.tenant.name
    secretStore = truenas_shared.shared.secretStores.default.name
    externalSecrets.htpasswd = _htpasswd
    charts.restic = restic.Chart {
        values = _values | restic.Values {
            global.nameOverride = name
            global.fullnameOverride = name
        }
    }
    routes.restic = gateway.Route {
        gatewayRef = truenas_shared.tenant.gateways.public
        services.server = {
            name = "restic"
            port = 8000
        }
    }
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        gatewayIngress = npt.envoyGatewayIngress
    }
}
