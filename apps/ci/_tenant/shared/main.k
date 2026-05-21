import ci_tenant
import konfig.models.frontend

tenant = ci_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "ci"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
