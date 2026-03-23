import truenas_tenant
import konfig.models.frontend

tenant = truenas_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "truenas"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
