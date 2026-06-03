import file
import json

import konfig.files
import konfig.objects
import konfig.models.frontend.secret

import cluster
import starr_radarr_base
import charts.radarr

_baseValues = starr_radarr_base.app.charts.radarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# All ExternalSecrets are repointed at the fake provider's single "dummy" key so
# they resolve offline (the local ClusterSecretStore only serves key "dummy").
_radarrCreds = secret.ExternalSecret {
    name = "radarr-credentials"
    data: {
        RADARR_AUTH_APIKEY.remoteRef.key = "dummy"
        RADARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
    }
}

_radarrOIDCClient = secret.ExternalSecret {
    name = "radarr-oidc-client"
    data: {
        "client-id" = {
            remoteRef.key = "dummy"
        }
        "client-secret" = {
            remoteRef.key = "dummy"
        }
    }
}

_tfVars = secret.ExternalSecret {
    name = "radarr-tfvars"
    data: {
        RADARR_AUTH_APIKEY.remoteRef.key = "dummy"
    }
    target.template.data: {
        ".auto.tfvars.json" = json.encode({
            "radarr_auth_apikey" = "{{.RADARR_AUTH_APIKEY}}"
        })
    }
}

# Local Docker-safe overlay:
# - domainName resolves to local.test via the clusters/local dep.
# - The OpenTofu ProviderConfig/Workspace extraResources are dropped: the
#   crossplane-opentofu runtime is not present locally and the workspace would
#   only fail trying to reach the Radarr API / postgres.
# - values.yaml clears the knas01 nodeSelector and swaps the NAS hostPath media
#   mount for an emptyDir.
app = starr_radarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.radarr.values = _values | radarr.Values {}

    externalSecrets: {
        radarrCreds = _radarrCreds
        radarrOIDCClient = _radarrOIDCClient
        radarrTFVars = _tfVars
    }

    extraResources.tofuProvider = Undefined
    extraResources.tofuWorkspace = Undefined
}
