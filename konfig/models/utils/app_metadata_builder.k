AppMetadataBuilder = lambda config -> {str:} {
    {
        name: config?.name
        labels: config?.labels
        annotations: {
            "argocd.argoproj.io/compare-options" = "ServerSideDiff=true,IncludeMutationWebhook=true"
        } | config?.annotations
        finalizers = ["resources-finalizer.argocd.argoproj.io"] if config?.prune else []
    }
}
