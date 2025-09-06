import cnpg_tenant
import konfig.models.frontend

tenant = cnpg_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "cnpg"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
