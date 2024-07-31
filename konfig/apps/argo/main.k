import konfig.models.frontend

tenantConfiguration: frontend.Tenant {
    name = "argo"

    destinations.legacy = {
        namespace = "argocd"
    }
}
