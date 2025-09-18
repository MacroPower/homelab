import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.prowlarr

_values = files.read_yaml(file.current(), "values.yaml")

_prowlarrCreds = secret.ExternalSecret {
    name = "prowlarr-credentials"
    data: {
        PROWLARR_AUTH_APIKEY = {}
        PROWLARR_POSTGRES_PASSWORD = {}
    }
}

_prowlarrOIDCClient = secret.ExternalSecret {
    name = "prowlarr-oidc-client"
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
    name = "prowlarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        prowlarrCreds = _prowlarrCreds
        prowlarrOIDCClient = _prowlarrOIDCClient
    }

    charts.prowlarr = prowlarr.Chart {
        values: _values | prowlarr.Values {}
    }

    routes.prowlarr = gateway.Route {
        gatewayRef = starr.tenant.gateways.default
        services.prowlarr = {
            name = "prowlarr"
            port = 9696
        }
        homepage = {
            name = "Prowlarr"
            description = "PVR Indexer Manager"
            group = "Media"
            icon = "prowlarr"
        }
        security = {
            oidcClientRef = _prowlarrOIDCClient.name
            oidcIssuer = starr.tenant.oidcIssuer
        }
    }
}
