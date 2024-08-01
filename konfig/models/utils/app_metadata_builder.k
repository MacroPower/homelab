AppMetadataBuilder = lambda config: any, options: ArgoCDOptions -> {str:} {
    if options?.compare or options?.sync:
        _options = _argoCDOptionMetadataBuilder(options)
    else:
        _options = _argoCDOptionMetadataBuilder(ArgoCDOptions {
            compare.ServerSideDiff = True
            compare.IncludeMutationWebhook = True
        })

    _options | {
        name: config?.name
        namespace: config?.namespace
        labels: config?.labels
        annotations: config?.annotations
        finalizers: ["resources-finalizer.argocd.argoproj.io"] if config?.prune else []
    }
}

_argoCDOptionMetadataBuilder = lambda aco: ArgoCDOptions -> {str:str} {
    _metadata = {}
    if aco.sync:
        _metadata = _metadata | {
            annotations = {
                "argocd.argoproj.io/sync-options" = ",".join([
                    "{}={}".format(k, str(v).lower())
                    for k, v in aco.sync
                    if v is not Undefined
                ])
            }
        }
    if aco.compare:
        _metadata = _metadata | {
            annotations = {
                "argocd.argoproj.io/compare-options" = ",".join([
                    "{}={}".format(k, str(v).lower())
                    for k, v in aco.compare
                    if v is not Undefined
                ])
            }
        }
    _metadata
}
