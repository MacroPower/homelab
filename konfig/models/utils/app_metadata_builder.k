AppMetadataBuilder = lambda config -> {str:} {
    ArgoCDOptionMetadataBuilder(ArgoCDOptions {
        compare.ServerSideDiff = True
        compare.IncludeMutationWebhook = True
    }) | {
        name: config?.name
        namespace: config?.namespace
        labels: config?.labels
        annotations: config?.annotations
        finalizers = ["resources-finalizer.argocd.argoproj.io"] if config?.prune else []
    }
}
