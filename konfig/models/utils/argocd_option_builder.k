ArgoCDOptionMetadataBuilder = lambda aco: ArgoCDOptions -> {str:str} {
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

schema ArgoCDOptions:
    """
    ArgoCD options to customize some aspects of the GitOps engine, per resource.

    Attributes
    ----------
    sync: ArgoCDSyncOptions, default is Undefined, optional.
        ArgoCD Sync Options
    compare: ArgoCDCompareOptions, default is Undefined, optional.
        ArgoCD Compare Options
    """
    sync?: ArgoCDSyncOptions
    compare?: ArgoCDCompareOptions

schema ArgoCDSyncOptions:
    """
    ArgoCD Sync Options
    https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/

    Attributes
    ----------
    Prune: bool, default is Undefined, optional.
        Set to `False` to prevent the resource from being pruned.
    Validate: bool, default is Undefined, optional.
        Set to `False` to disable kubectl validation.
    SkipDryRunOnMissingResource: bool, default is Undefined, optional.
        Set to `True` to skip dry-run for new custom resources types. This is
        useful when the CRD manifest is part of the same sync, or when the CRD
        is not part of the sync, but could be created in another way, e.g. by a
        controller in the cluster.
    Delete: bool, default is Undefined, optional.
        Set to `False` to always retain the resource, even if a parent
        Application is deleted with a deletion finalizer. This can be useful for
        resources like PersistentVolumeClaim.
    PruneLast: bool, default is Undefined, optional.
        Set to `True` to allow the ability for resource pruning to happen as a
        final, implicit wave of a sync operation, after the other resources have
        been deployed and become healthy, and after all other waves completed
        successfully.
    Replace: bool, default is Undefined, optional.
        Set to `True` to replace the resource in-place instead of applying
        changes. This can be useful for immutable resources like StorageClass,
        and for cases where the resource spec is too large to patch without
        ServerSideApply. To execute this, ArgoCD uses `kubectl replace`.
    Force: bool, default is Undefined, optional.
        Set to `True` to force delete and subsequently create the resource.
        To execute this, ArgoCD uses `kubectl delete --force`, followed by
        `kubectl create`. You can use optionally use `Force` with `Replace` to
        perform a forced in-place replacement.
    ServerSideApply: bool, default is Undefined, optional.
        Set to `True` to use Server-Side Apply for the resource.
        https://kubernetes.io/docs/reference/using-api/server-side-apply/
    """
    Prune?: bool
    Validate?: bool
    SkipDryRunOnMissingResource?: bool
    Delete?: bool
    PruneLast?: bool
    Replace?: bool
    Force?: bool
    ServerSideApply?: bool

schema ArgoCDCompareOptions:
    """
    ArgoCD Compare Options
    https://argo-cd.readthedocs.io/en/stable/user-guide/compare-options/
    https://argo-cd.readthedocs.io/en/stable/user-guide/diff-strategies/

    Attributes
    ----------
    IgnoreExtraneous: bool, default is Undefined, optional.
        Set to `True` to exclude the resource from the Application's sync
        status. This only affects the sync status. If the resource's health is
        degraded, then the Application will also be degraded.
    ServerSideDiff: bool, default is Undefined, optional.
        Set to `True` to enable the Server-Side Diff strategy.
    IncludeMutationWebhook: bool, default is Undefined, optional.
        Set to `True` to include changes made by mutation webhooks in
        Server-Side Diffs. This option is only effective when `ServerSideDiff`
        is also set to `True`.
    """
    IgnoreExtraneous?: bool
    ServerSideDiff?: bool
    IncludeMutationWebhook?: bool
