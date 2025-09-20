import securecodebox_tenant
import konfig.models.frontend

tenant = securecodebox_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "securecodebox"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
