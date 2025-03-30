import konfig.models.frontend

tenantConfiguration: frontend.Tenant {
    name = "argo"

    secretStores.default = {
        name = "argo"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
