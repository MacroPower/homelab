"""
This file was generated by the KCL auto-gen tool. DO NOT EDIT.
Editing this file might prove futile when you re-run the KCL auto-gen generate command.
"""
import k8s.apimachinery.pkg.apis.meta.v1


schema ProviderConfig:
    """
    A ProviderConfig configures a SQL provider.

    Attributes
    ----------
    apiVersion : str, default is "mssql.sql.crossplane.io/v1alpha1", required
        APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
    kind : str, default is "ProviderConfig", required
        Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
    metadata : v1.ObjectMeta, default is Undefined, optional
        metadata
    spec : MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpec, default is Undefined, required
        spec
    status : MssqlSQLCrossplaneIoV1alpha1ProviderConfigStatus, default is Undefined, optional
        status
    """


    apiVersion: "mssql.sql.crossplane.io/v1alpha1" = "mssql.sql.crossplane.io/v1alpha1"

    kind: "ProviderConfig" = "ProviderConfig"

    metadata?: v1.ObjectMeta

    spec: MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpec

    status?: MssqlSQLCrossplaneIoV1alpha1ProviderConfigStatus


schema MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpec:
    """
    A ProviderConfigSpec defines the desired state of a ProviderConfig.

    Attributes
    ----------
    credentials : MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpecCredentials, default is Undefined, required
        credentials
    """


    credentials: MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpecCredentials


schema MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpecCredentials:
    """
    Credentials required to authenticate to this provider.

    Attributes
    ----------
    connectionSecretRef : MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpecCredentialsConnectionSecretRef, default is Undefined, optional
        connection secret ref
    source : str, default is Undefined, required
        Source of the provider credentials.
    """


    connectionSecretRef?: MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpecCredentialsConnectionSecretRef

    source: "MSSQLConnectionSecret"


schema MssqlSQLCrossplaneIoV1alpha1ProviderConfigSpecCredentialsConnectionSecretRef:
    """
    A CredentialsSecretRef is a reference to a MSSQL connection secret that contains the credentials that must be used to connect to the provider.

    Attributes
    ----------
    name : str, default is Undefined, required
        Name of the secret.
    namespace : str, default is Undefined, required
        Namespace of the secret.
    """


    name: str

    namespace: str


schema MssqlSQLCrossplaneIoV1alpha1ProviderConfigStatus:
    """
    A ProviderConfigStatus reflects the observed state of a ProviderConfig.

    Attributes
    ----------
    conditions : [MssqlSQLCrossplaneIoV1alpha1ProviderConfigStatusConditionsItems0], default is Undefined, optional
        Conditions of the resource.
    users : int, default is Undefined, optional
        Users of this provider configuration.
    """


    conditions?: [MssqlSQLCrossplaneIoV1alpha1ProviderConfigStatusConditionsItems0]

    users?: int


schema MssqlSQLCrossplaneIoV1alpha1ProviderConfigStatusConditionsItems0:
    """
    A Condition that may apply to a resource.

    Attributes
    ----------
    lastTransitionTime : str, default is Undefined, required
        LastTransitionTime is the last time this condition transitioned from one status to another.
    message : str, default is Undefined, optional
        A Message containing details about this condition's last transition from one status to another, if any.
    reason : str, default is Undefined, required
        A Reason for this condition's last transition from one status to another.
    status : str, default is Undefined, required
        Status of this condition; is it currently True, False, or Unknown?
    $type : str, default is Undefined, required
        Type of this condition. At most one of each condition type may apply to a resource at any point in time.
    """


    lastTransitionTime: str

    message?: str

    reason: str

    status: str

    $type: str


