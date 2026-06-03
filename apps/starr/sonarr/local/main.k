import file

import konfig.files
import konfig.objects

import starr_sonarr_base
import cluster
import charts.sonarr

_baseValues = starr_sonarr_base.app.charts.sonarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe local overlay:
# - clear the knas01 nodeSelector and switch the media hostPath volume to emptyDir
#   (handled in values.yaml; the tald node has neither the label nor the NAS path)
# - drop the OpenTofu ProviderConfig/Workspace extraResources: those CRDs and the
#   sonarr API they target are not available offline
# - point every ExternalSecret remoteRef.key at the constant "dummy" the fake
#   ClusterSecretStore serves; the real Doppler-backed keys cannot resolve offline
app = starr_sonarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.sonarr.values = _values | sonarr.Values {}

    extraResources.tofuProvider = Undefined
    extraResources.tofuWorkspace = Undefined

    externalSecrets.sonarrCreds.data.SONARR_AUTH_APIKEY.remoteRef.key = "dummy"
    externalSecrets.sonarrCreds.data.SONARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
    externalSecrets.sonarrOIDCClient.data: {
        "client-id": {remoteRef.key = "dummy"}
        "client-secret": {remoteRef.key = "dummy"}
    }
    externalSecrets.sonarrTFVars.data.SONARR_AUTH_APIKEY.remoteRef.key = "dummy"
}
