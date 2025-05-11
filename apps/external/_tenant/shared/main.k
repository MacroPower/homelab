import external_tenant
import konfig.models.frontend

tenant = external_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "external"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
