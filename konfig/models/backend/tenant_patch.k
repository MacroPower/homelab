schema BackendTenantPatch:
    """
    Application-level patch.

    Parameters
    ----------
    source: BackendTenantPatchSource, optional
        Git repository used to extract the desired Application manifests.
    syncPolicy: BackendTenantPatchSyncPolicy, optional
        The synchronization policy for the application.
    ignoreDifferences: [BackendTenantPatchIgnoreDifferences], optional
        List of differences to ignore during synchronization.
    info: [BackendTenantPatchInfo], optional
        Additional information to display on the Argo CD dashboard.
    """
    source?: BackendTenantPatchSource
    syncPolicy?: BackendTenantPatchSyncPolicy
    ignoreDifferences?: [BackendTenantPatchIgnoreDifferences]
    info?: [BackendTenantPatchInfo]

# argov1alpha1.ArgoprojIoV1alpha1ApplicationSetSpecTemplateSpecSource
schema BackendTenantPatchSource:
    """
    Git repository used to extract the desired Application manifests.

    Parameters
    ----------
    targetRevision: str, optional
        Revision (tag/branch/commit) of the repository (e.g. `HEAD`).
    """
    targetRevision?: str

# argov1alpha1.ArgoprojIoV1alpha1ApplicationSetSpecTemplateSpecIgnoreDifferencesItems0
schema BackendTenantPatchIgnoreDifferences:
    """
    Ignore differences at a specific JSON path, using RFC6902 JSON patches and
    JQ path expressions.

    https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/
    """
    group?: str
    jqPathExpressions?: [str]
    jsonPointers?: [str]
    kind: str
    managedFieldsManagers?: [str]
    name?: str
    namespace?: str

# argov1alpha1.ArgoprojIoV1alpha1ApplicationSetSpecTemplateSpecInfoItems0
schema BackendTenantPatchInfo:
    """
    Add additional information to an Application on your Argo CD dashboard.

    https://argo-cd.readthedocs.io/en/stable/user-guide/extra_info/

    Parameters
    ----------
    name: str, required
        Name of the info item.
    value: str, required
        Value of the info item.
    """
    name: str
    value: str

# argov1alpha1.ArgoprojIoV1alpha1ApplicationSetSpecTemplateSpecSyncPolicy
schema BackendTenantPatchSyncPolicy:
    """
    Customize some aspects of how the Application syncs the desired state in the
    target cluster.

    Parameters
    ----------
    automated: BackendTenantPatchSyncPolicyAutomated, optional
        Automated synchronization policy for the application.
    """
    automated?: BackendTenantPatchSyncPolicyAutomated

# argov1alpha1.ArgoprojIoV1alpha1ApplicationSetSpecTemplateSpecSyncPolicyAutomated
schema BackendTenantPatchSyncPolicyAutomated:
    """
    Automatically sync an application when it detects differences between the
    desired manifests in Git, and the live state in the cluster.

    https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/

    Parameters
    ----------
    allowEmpty: bool, optional
        Allow applications to have empty resources.
    prune: bool, optional
        Delete resources when Argo CD detects the resource is no longer defined
        in Git.
    selfHeal: bool, optional
        Enable automatic sync when the live cluster's state deviates from the
        state defined in Git.
    """
    allowEmpty?: bool
    prune?: bool
    selfHeal?: bool

