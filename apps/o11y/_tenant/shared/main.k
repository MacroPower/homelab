import o11y_tenant
import konfig.models.frontend

tenant = o11y_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "o11y"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
