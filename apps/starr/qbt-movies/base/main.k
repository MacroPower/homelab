import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.qbittorrent as qbt

_values = files.read_yaml(file.current(), "values.yaml")

_qbtOIDCClient = secret.ExternalSecret {
    name = "qbt-oidc-client"
    data: {
        "client-id" = {
            remoteRef.key = "STARR_AUTH0_CLIENT_ID"
        }
        "client-secret" = {
            remoteRef.key = "STARR_AUTH0_CLIENT_SECRET"
        }
    }
}

app = frontend.App {
    name = "qbt-movies"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        qbtOIDCClient = _qbtOIDCClient
    }

    charts.qbt = qbt.Chart {
        values: _values | qbt.Values {
            global: {
                fullnameOverride = name
                nameOverride = name
            }
        }
    }

    routes.qbt = gateway.Route {
        gatewayRef = starr.tenant.gateways.default
        services.qbt = {
            name = "qbt-movies-web"
            port = 8080
        }
        homepage = {
            name = "qBittorrent - MOVIES"
            description = "qBittorrent Web UI"
            group = "Media"
            icon = "qbittorrent"
        }
        security = {
            oidcClientRef = _qbtOIDCClient.name
            oidcIssuer = starr.tenant.oidcIssuer
        }
    }
}
