import cluster
import starr_qbt_tv_base

# Docker-safe local overlay.
# - domainName comes from clusters/local (resolves to local.test).
# - The qbt OIDC ExternalSecret reads real Doppler keys
#   (STARR_AUTH0_CLIENT_ID/SECRET); redirect every remoteRef.key to "dummy"
#   so the fake secret provider answers offline.
# - The chart's 18Gi memory limit is reduced to 2Gi so the pod fits the
#   single tald node. (This app's base App re-reads only its own values.yaml,
#   so the override is applied here as a typed patch on the chart value.)
app = starr_qbt_tv_base.app | {
    domainName = cluster.DOMAIN_NAME

    externalSecrets.qbtOIDCClient.data = {
        "client-id" = {remoteRef.key = "dummy"}
        "client-secret" = {remoteRef.key = "dummy"}
    }

    charts.qbt.values.controllers.qbittorrent.containers.app.resources.limits.memory = "2Gi"
}
