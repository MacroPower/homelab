import file

import konfig.files
import konfig.objects

import cluster
import starr_prowlarr_base
import charts.prowlarr

_baseValues = starr_prowlarr_base.app.charts.prowlarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe local overlay:
#   - Drop the OpenTofu ProviderConfig/Workspace extraResources: the crossplane
#     OpenTofu provider CRDs are not installed on the local tald cluster.
#   - Point every ExternalSecret remoteRef.key at "dummy" so the fake offline
#     ClusterSecretStore (which only serves key="dummy") can resolve them.
#   - Persistence is already emptyDir in base; postgres lives in starr-system and
#     is absent locally, so the app runs degraded (no DB backend).
app = starr_prowlarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.prowlarr.values = _values | prowlarr.Values {}

    extraResources.tofuProvider = Undefined
    extraResources.tofuWorkspace = Undefined

    externalSecrets.prowlarrCreds.data.PROWLARR_AUTH_APIKEY.remoteRef.key = "dummy"
    externalSecrets.prowlarrCreds.data.PROWLARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"

    externalSecrets.prowlarrOIDCClient.data = {
        "client-id" = {remoteRef.key = "dummy"}
        "client-secret" = {remoteRef.key = "dummy"}
    }

    externalSecrets.prowlarrTFVars.data.SONARR_AUTH_APIKEY.remoteRef.key = "dummy"
    externalSecrets.prowlarrTFVars.data.RADARR_AUTH_APIKEY.remoteRef.key = "dummy"
    externalSecrets.prowlarrTFVars.data.PROWLARR_AVISTAZ_INDEXERS.remoteRef.key = "dummy"
}
