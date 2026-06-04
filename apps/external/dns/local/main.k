import external_dns_base

# Local Docker-safe overlay. The external-dns app talks to real DNS backends
# (Cloudflare API and a UniFi webhook), neither of which is reachable from the
# offline tald cluster, so this renders the manifests but the controllers stay
# degraded. Every ExternalSecret remoteRef.key is repointed to "dummy" so the
# fake secret provider answers them and the ExternalSecrets reconcile.
app = external_dns_base.app | {
    externalSecrets: {
        cloudflareCreds.data: {
            CLOUDFLARE_API_EMAIL.remoteRef.key = "dummy"
            CLOUDFLARE_API_TOKEN.remoteRef.key = "dummy"
        }
        unifiCreds.data: {
            UNIFI_HOST.remoteRef.key = "dummy"
            UNIFI_USER.remoteRef.key = "dummy"
            UNIFI_PASS.remoteRef.key = "dummy"
        }
    }
}
