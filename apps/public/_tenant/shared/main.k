import public_tenant
import konfig.models.frontend

tenant = public_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "public"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
