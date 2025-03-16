AppMetadataBuilder = lambda config: any, options: ArgoCDOptions -> {str:} {
    _options = options

    if not options.compare?.ServerSideDiff:
        _options.compare.ServerSideDiff = True
    if not options.compare?.IncludeMutationWebhook:
        _options.compare.IncludeMutationWebhook = True
    if not options?.finalize:
        _options.finalize = True

    _argoCDOptionMetadataBuilder(_options) | {
        name: config?.name
        namespace: config?.namespace
        labels: config?.labels
        annotations: config?.annotations
    }
}

_argoCDOptionMetadataBuilder = lambda aco: ArgoCDOptions -> {str:} {
    _syncOptions = ",".join([
        "{}={}".format(k, str(v).lower())
        for k, v in aco.sync
        if v is not Undefined
    ])

    _compareOptions = ",".join([
        "{}={}".format(k, str(v).lower())
        for k, v in aco.compare
        if v is not Undefined
    ])

    _finalizers: [str] = ["resources-finalizer.argocd.argoproj.io"] if aco.finalize else []

    _metadata: {str:} = {    }

    if _syncOptions != "":
        _metadata.annotations |= {
            "argocd.argoproj.io/sync-options" = _syncOptions
        }
    if _compareOptions != "":
        _metadata.annotations |= {
            "argocd.argoproj.io/compare-options" = _compareOptions
        }

    if len(_finalizers) > 0:
        _metadata.finalizers = _finalizers

    _metadata
}
