import external_dns_base

# Local Docker-safe overlay. The real DNS backends (Cloudflare API, UniFi
# webhook) are unreachable from the offline tald cluster -- with the base's
# webhook provider both containers crashloop (the sidecar fatals on login, then
# external-dns fatals dialing it). Swap the provider for external-dns' built-in
# `inmemory`: the sidecar is dropped (the chart renders it only for
# provider.name == "webhook") and external-dns runs functionally, reconciling
# the real service/ingress/gateway-httproute sources into an in-memory zone.
# Every ExternalSecret remoteRef.key is repointed to "dummy" so the fake secret
# provider answers them and the ExternalSecrets reconcile.
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

    charts.external_dns_unifi.values.provider = {
        name = "inmemory"
    }
}
