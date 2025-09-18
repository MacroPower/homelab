import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.sonarr

_values = files.read_yaml(file.current(), "values.yaml")

_sonarrCreds = secret.ExternalSecret {
    name = "sonarr-credentials"
    data: {
        SONARR_AUTH_APIKEY = {}
        SONARR_POSTGRES_PASSWORD = {}
    }
}

_sonarrOIDCClient = secret.ExternalSecret {
    name = "sonarr-oidc-client"
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
    name = "sonarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        sonarrCreds = _sonarrCreds
        sonarrOIDCClient = _sonarrOIDCClient
    }

    charts.sonarr = sonarr.Chart {
        values: _values | sonarr.Values {}
    }

    routes.sonarr = gateway.Route {
        gatewayRef = starr.tenant.gateways.default
        services.sonarr = {
            name = "sonarr"
            port = 8989
        }
        homepage = {
            name = "Sonarr"
            description = "PVR, Manager & Organizer for TV"
            group = "Media"
            icon = "sonarr"
        }
        security = {
            oidcClientRef = _sonarrOIDCClient.name
            oidcIssuer = starr.tenant.oidcIssuer
        }
    }
}
