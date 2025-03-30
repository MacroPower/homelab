import argo_tenant
import konfig.models.frontend

tenant = argo_tenant.tenantConfiguration

shared: frontend.SharedApp {
    secretStores.default = {
        name = "argo"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
