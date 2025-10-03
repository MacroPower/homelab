import file
import json

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.radarr
import charts.opentofu.api.v1beta1 as opentofu

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

_tfVars = secret.ExternalSecret {
    name = "radarr-tfvars"
    data: {
        RADARR_AUTH_APIKEY = {}
    }
    target.template.data: {
        ".auto.tfvars.json" = json.encode({
            "radarr_auth_apikey" = "{{.RADARR_AUTH_APIKEY}}"
        })
    }
}

tofuProvider = opentofu.ProviderConfig {
    metadata: {
        name = "radarr"
        namespace = "starr-radarr"
    }
    spec: {
        credentials = [{
            filename = "radarr-apikey"
            source = "Secret"
            secretRef: {
                namespace = "starr-radarr"
                name = _radarrCreds.name
                key = "RADARR_AUTH_APIKEY"
            }
        }]
        configuration = files.read_file(file.current(), "tofu/providers.tf")
    }
}

tofuWorkspace = opentofu.Workspace {
    metadata: {
        name = "radarr"
        namespace = "starr-radarr"
    }
    spec: {
        providerConfigRef: {
            kind = "ProviderConfig"
            name = "radarr"
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
    name = "radarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        radarrCreds = _radarrCreds
        radarrOIDCClient = _radarrOIDCClient
        radarrTFVars = _tfVars
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
        homepage = {
            name = "Radarr"
            description = "PVR, Manager & Organizer for Movies"
            group = "Media"
            icon = "radarr"
        }
        security = {
            oidcClientRef = _radarrOIDCClient.name
            oidcIssuer = starr.tenant.oidcIssuer
        }
    }

    extraResources: {
        tofuProvider = tofuProvider
        tofuWorkspace = tofuWorkspace
    }
}
