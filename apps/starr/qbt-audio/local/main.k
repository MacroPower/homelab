import cluster
import starr_qbt_audio_base

# Docker-safe local overlay for the tald single-node test cluster.
# - Redirect the qBittorrent OIDC ExternalSecret data keys to the fake provider's
#   "dummy" key (no real Auth0/Doppler offline).
# - Resources are inherited from base: the render context minimizes requests, so
#   the prod 18Gi memory limit never blocks scheduling here. PVCs already use
#   openebs-hostpath and downloads is emptyDir, so storage needs no changes.
app = starr_qbt_audio_base.app | {
    domainName = cluster.DOMAIN_NAME

    externalSecrets.qbtOIDCClient.data = {
        "client-id" = {remoteRef.key = "dummy"}
        "client-secret" = {remoteRef.key = "dummy"}
    }
}
