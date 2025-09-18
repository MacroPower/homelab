import file

import konfig.models.frontend
import konfig.models.frontend.configmap
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.frontend.secret
import konfig.models.templates.networkpolicy as npt
import konfig.files

import twitch
import charts.tcpm

_values = files.read_yaml(file.current(), "values.yaml")

runConfig = files.read_file(file.current(), "config/run.py")

_tcpmOIDCClient = secret.ExternalSecret {
    name = "tcpm-oidc-client"
    data: {
        "client-id" = {
            remoteRef.key = "LAB_ADMIN_AUTH0_CLIENT_ID"
        }
        "client-secret" = {
            remoteRef.key = "LAB_ADMIN_AUTH0_CLIENT_SECRET"
        }
    }
}

_twitchCookie = secret.ExternalSecret {
    name = "twitch-cookie"
    data: {
        "Cookie.pkl" = {
            remoteRef = {
                key = "TWITCH_COOKIE"
                decodingStrategy = "Base64"
            }
        }
    }
}

app = frontend.App {
    name = "channel-points-miner"
    tenantName = twitch.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        internetIPv4Egress = npt.internetIPv4Egress
        internetIPv6Egress = npt.internetIPv6Egress
        gatewayIngress = npt.envoyGatewayIngress
    }

    secretStore = twitch.shared.secretStores.default.name
    externalSecrets: {
        tcpmOIDCClient = _tcpmOIDCClient
        twitchCookie = _twitchCookie
    }

    charts.tcpm = tcpm.Chart {
        values: _values | tcpm.Values {}
    }

    configMaps.runConfig = configmap.ConfigMap {
        name = "twitch-config"
        data: {
            "run.py" = runConfig
        }
    }

    routes.tcpm = gateway.Route {
        hostnames = ["tcpm"]
        gatewayRef = twitch.tenant.gateways.default
        services.tcpm = {
            name = "twitch-channel-points-miner"
            port = 5000
        }
        homepage = {
            name = "Twitch Channel Points Miner"
            description = "Automated Points Collector & Gamba Participant"
            group = "Apps"
            icon = "twitch"
        }
        security = {
            oidcClientRef = _tcpmOIDCClient.name
            oidcIssuer = twitch.tenant.oidcIssuer
        }
    }
}
