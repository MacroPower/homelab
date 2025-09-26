import file

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.files

import starr
import qbt_base
import charts.qbittorrent as qbt

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "qbt-tv"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        qbtOIDCClient = qbt_base.oidcClient
    }

    charts.qbt = qbt.Chart {
        values: qbt_base.values | _values | qbt.Values {
            global: {
                fullnameOverride = name
                nameOverride = name
            }
        }
    }

    routes.qbt = gateway.Route {
        gatewayRef = starr.tenant.gateways.default
        services.qbt = {
            name = "qbt-tv-web"
            port = 8080
        }
        homepage = {
            name = "qBittorrent - TV"
            description = "qBittorrent Web UI"
            group = "Media"
            icon = "qbittorrent"
        }
        security = {
            oidcClientRef = qbt_base.oidcClient.name
            oidcIssuer = starr.tenant.oidcIssuer
        }
    }
}
