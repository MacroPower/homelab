import twitch_tenant
import konfig.models.frontend

tenant = twitch_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "twitch"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
