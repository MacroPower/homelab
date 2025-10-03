import file
import json

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.sonarr
import charts.opentofu.api.v1beta1 as opentofu

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

_tfVars = secret.ExternalSecret {
    name = "sonarr-tfvars"
    data: {
        SONARR_AUTH_APIKEY = {}
    }
    target.template.data: {
        ".auto.tfvars.json" = json.encode({
            "sonarr_auth_apikey" = "{{.SONARR_AUTH_APIKEY}}"
        })
    }
}

tofuProvider = opentofu.ProviderConfig {
    metadata: {
        name = "sonarr"
        namespace = "starr-sonarr"
    }
    spec: {
        credentials = [{
            filename = "sonarr-apikey"
            source = "Secret"
            secretRef: {
                namespace = "starr-sonarr"
                name = _sonarrCreds.name
                key = "SONARR_AUTH_APIKEY"
            }
        }]
        configuration = files.read_file(file.current(), "tofu/providers.tf")
    }
}

tofuWorkspace = opentofu.Workspace {
    metadata: {
        name = "sonarr"
        namespace = "starr-sonarr"
    }
    spec: {
        providerConfigRef: {
            kind = "ProviderConfig"
            name = "sonarr"
        }
        forProvider: {
            initArgs = ["-upgrade=true"]
            varFiles = [{
                source = "SecretKey"
                format = "JSON"
                secretKeyRef: {
                    name = _tfVars.name
                    key = ".auto.tfvars.json"
                }
            }]
            vars = []
            source = "Inline"
            module = files.read_file(file.current(), "tofu/main.tf")
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
        prowlarrTFVars = _tfVars
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

    extraResources: {
        tofuProvider = tofuProvider
        tofuWorkspace = tofuWorkspace
    }
}
