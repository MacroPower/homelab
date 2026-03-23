import file

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.files

import starr_shared
import qbt_base
import charts.qbittorrent as qbt

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "qbt-movies"
    tenantName = starr_shared.tenant.name

    secretStore = starr_shared.shared.secretStores.default.name
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
        gatewayRef = starr_shared.tenant.gateways.default
        services.qbt = {
            name = "qbt-movies-web"
            port = 8080
        }
        homepage = {
            name = "qBittorrent - Movies"
            description = "qBittorrent Web UI"
            group = "Media"
            icon = "qbittorrent"
        }
        security = {
            oidcClientRef = qbt_base.oidcClient.name
            oidcIssuer = starr_shared.tenant.oidcIssuer
        }
    }
}
