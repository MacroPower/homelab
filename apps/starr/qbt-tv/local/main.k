import cluster
import starr_qbt_tv_base

# Docker-safe local overlay.
# - domainName comes from clusters/local (resolves to local.test).
# - The qbt OIDC ExternalSecret reads real Doppler keys
#   (STARR_AUTH0_CLIENT_ID/SECRET); redirect every remoteRef.key to "dummy"
#   so the fake secret provider answers offline.
# - Resources are inherited from base: the render context minimizes requests,
#   so the prod 18Gi memory limit never blocks scheduling here.
app = starr_qbt_tv_base.app | {
    domainName = cluster.DOMAIN_NAME

    externalSecrets.qbtOIDCClient.data = {
        "client-id" = {remoteRef.key = "dummy"}
        "client-secret" = {remoteRef.key = "dummy"}
    }
}
