import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.radarr

_values = files.read_yaml(file.current(), "values.yaml")

_radarrCreds = secret.ExternalSecret {
    name = "radarr-credentials"
    data: {
        RADARR_AUTH_APIKEY = {}
        RADARR_POSTGRES_PASSWORD = {}
    }
}

_radarrOIDCClient = secret.ExternalSecret {
    name = "radarr-oidc-client"
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
    name = "radarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        radarrCreds = _radarrCreds
        radarrOIDCClient = _radarrOIDCClient
    }

    charts.radarr = radarr.Chart {
        values: _values | radarr.Values {}
    }

    routes.radarr = gateway.Route {
        gatewayRef = starr.tenant.gateways.default
        services.radarr = {
            name = "radarr"
            port = 7878
        }
        security = gateway.SecurityPolicy {
            oidcClientRef = _radarrOIDCClient.name
            oidcIssuer = starr.tenant.oidcIssuer
        }
    }
}
