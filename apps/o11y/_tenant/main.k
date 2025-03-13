import konfig.models.frontend

tenantConfiguration: frontend.Tenant {
    name = "o11y"

    secretStores.default = {
        name = "o11y"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
