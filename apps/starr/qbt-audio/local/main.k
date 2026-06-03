import cluster
import starr_qbt_audio_base

# Docker-safe local overlay for the tald single-node test cluster.
# - Redirect the qBittorrent OIDC ExternalSecret data keys to the fake provider's
#   "dummy" key (no real Auth0/Doppler offline).
# - Memory limit is trimmed from 18Gi -> 2Gi so the pod schedules on the single
#   node. PVCs already use openebs-hostpath and downloads is emptyDir, so storage
#   needs no further changes.
# The base assembles chart values from its own values.yaml, so the override is
# applied here as a typed patch rather than via this overlay's values.yaml.
app = starr_qbt_audio_base.app | {
    domainName = cluster.DOMAIN_NAME

    externalSecrets.qbtOIDCClient.data = {
        "client-id" = {remoteRef.key = "dummy"}
        "client-secret" = {remoteRef.key = "dummy"}
    }

    charts.qbt.values.controllers.qbittorrent.containers.app.resources.limits.memory = "2Gi"
}
