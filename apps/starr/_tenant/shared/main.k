import starr_tenant
import konfig.models.frontend

tenant = starr_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "starr"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
