import file
import json

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.files

import starr
import charts.prowlarr
import charts.opentofu.api.v1beta1 as opentofu

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

_tfVars = secret.ExternalSecret {
    name = "prowlarr-tfvars"
    data: {
        SONARR_AUTH_APIKEY = {}
        RADARR_AUTH_APIKEY = {}
        PROWLARR_TV_MOVIE_INDEXER_IMPLEMENTATION = {}
        PROWLARR_TV_MOVIE_INDEXER_CONFIG_CONTRACT = {}
        PROWLARR_TV_MOVIE_INDEXER_BASE_URL = {}
        PROWLARR_TV_MOVIE_INDEXER_USERNAME = {}
        PROWLARR_TV_MOVIE_INDEXER_PASSWORD = {}
        PROWLARR_TV_MOVIE_INDEXER_PID = {}
    }
    target.template.data: {
        ".auto.tfvars.json" = json.encode({
            "sonarr_auth_apikey" = "{{.SONARR_AUTH_APIKEY}}"
            "radarr_auth_apikey" = "{{.RADARR_AUTH_APIKEY}}"
            "tv_movie_indexer_implementation" = "{{.PROWLARR_TV_MOVIE_INDEXER_IMPLEMENTATION}}"
            "tv_movie_indexer_config_contract" = "{{.PROWLARR_TV_MOVIE_INDEXER_CONFIG_CONTRACT}}"
            "tv_movie_indexer_base_url" = "{{.PROWLARR_TV_MOVIE_INDEXER_BASE_URL}}"
            "tv_movie_indexer_username" = "{{.PROWLARR_TV_MOVIE_INDEXER_USERNAME}}"
            "tv_movie_indexer_password" = "{{.PROWLARR_TV_MOVIE_INDEXER_PASSWORD}}"
            "tv_movie_indexer_pid" = "{{.PROWLARR_TV_MOVIE_INDEXER_PID}}"
        })
    }
}

tofuProvider = opentofu.ProviderConfig {
    metadata: {
        name = "prowlarr"
        namespace = "starr-prowlarr"
    }
    spec: {
        credentials = [{
            filename = "prowlarr-apikey"
            source = "Secret"
            secretRef: {
                namespace = "starr-prowlarr"
                name = _prowlarrCreds.name
                key = "PROWLARR_AUTH_APIKEY"
            }
        }]
        configuration = files.read_file(file.current(), "tofu/providers.tf")
    }
}

tofuWorkspace = opentofu.Workspace {
    metadata: {
        name = "prowlarr"
        namespace = "starr-prowlarr"
    }
    spec: {
        providerConfigRef: {
            kind = "ProviderConfig"
            name = "prowlarr"
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
    name = "prowlarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets: {
        prowlarrCreds = _prowlarrCreds
        prowlarrOIDCClient = _prowlarrOIDCClient
        prowlarrTFVars = _tfVars
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

    extraResources: {
        tofuProvider = tofuProvider
        tofuWorkspace = tofuWorkspace
    }
}
