"""
This file was generated by the KCL auto-gen tool. DO NOT EDIT.
Editing this file might prove futile when you re-run the KCL auto-gen generate command.
"""
import k8s.apimachinery.pkg.apis.meta.v1


schema Database:
    """
    A Database represents the declarative state of a PostgreSQL database.

    Attributes
    ----------
    apiVersion : str, default is "postgresql.sql.crossplane.io/v1alpha1", required
        APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
    kind : str, default is "Database", required
        Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
    metadata : v1.ObjectMeta, default is Undefined, optional
        metadata
    spec : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpec, default is Undefined, required
        spec
    status : PostgresqlSQLCrossplaneIoV1alpha1DatabaseStatus, default is Undefined, optional
        status
    """


    apiVersion: "postgresql.sql.crossplane.io/v1alpha1" = "postgresql.sql.crossplane.io/v1alpha1"

    kind: "Database" = "Database"

    metadata?: v1.ObjectMeta

    spec: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpec

    status?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseStatus


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpec:
    """
    A DatabaseSpec defines the desired state of a Database.

    Attributes
    ----------
    deletionPolicy : str, default is "Delete", optional
        DeletionPolicy specifies what will happen to the underlying external when this managed resource is deleted - either "Delete" or "Orphan" the external resource.
    forProvider : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecForProvider, default is Undefined, required
        for provider
    providerConfigRef : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderConfigRef, default is Undefined, optional
        provider config ref
    providerRef : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderRef, default is Undefined, optional
        provider ref
    publishConnectionDetailsTo : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsTo, default is Undefined, optional
        publish connection details to
    writeConnectionSecretToRef : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecWriteConnectionSecretToRef, default is Undefined, optional
        write connection secret to ref
    """


    deletionPolicy?: "Orphan" | "Delete" = "Delete"

    forProvider: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecForProvider

    providerConfigRef?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderConfigRef

    providerRef?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderRef

    publishConnectionDetailsTo?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsTo

    writeConnectionSecretToRef?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecWriteConnectionSecretToRef


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecForProvider:
    """
    DatabaseParameters are the configurable fields of a Database.

    Attributes
    ----------
    allowConnections : bool, default is Undefined, optional
        If false then no one can connect to this database. The default is true, allowing connections (except as restricted by other mechanisms, such as GRANT/REVOKE CONNECT).
    connectionLimit : int, default is Undefined, optional
        How many concurrent connections can be made to this database. -1 (the default) means no limit.
    encoding : str, default is Undefined, optional
        Character set encoding to use in the new database. Specify a string constant (e.g., 'SQL_ASCII'), or an integer encoding number, or DEFAULT to use the default encoding (namely, the encoding of the template database). The character sets supported by the PostgreSQL server are described in Section 23.3.1. See below for additional restrictions.
    isTemplate : bool, default is Undefined, optional
        If true, then this database can be cloned by any user with CREATEDB privileges; if false (the default), then only superusers or the owner of the database can clone it.
    lcCType : str, default is Undefined, optional
        Character classification (LC_CTYPE) to use in the new database. This affects the categorization of characters, e.g. lower, upper and digit. The default is to use the character classification of the template database. See below for additional restrictions.
    lcCollate : str, default is Undefined, optional
        Collation order (LC_COLLATE) to use in the new database. This affects the sort order applied to strings, e.g. in queries with ORDER BY, as well as the order used in indexes on text columns. The default is to use the collation order of the template database. See below for additional restrictions.
    owner : str, default is Undefined, optional
        The role name of the user who will own the new database, or DEFAULT to use the default (namely, the user executing the command). To create a database owned by another role, you must be a direct or indirect member of that role, or be a superuser.
    tablespace : str, default is Undefined, optional
        The name of the tablespace that will be associated with the new database, or DEFAULT to use the template database's tablespace. This tablespace will be the default tablespace used for objects created in this database. See CREATE TABLESPACE for more information.
    template : str, default is Undefined, optional
        The name of the template from which to create the new database, or DEFAULT to use the default template (template1).
    """


    allowConnections?: bool

    connectionLimit?: int

    encoding?: str

    isTemplate?: bool

    lcCType?: str

    lcCollate?: str

    owner?: str

    tablespace?: str

    template?: str


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderConfigRef:
    """
    ProviderConfigReference specifies how the provider that will be used to create, observe, update, and delete this managed resource should be configured.

    Attributes
    ----------
    name : str, default is Undefined, required
        Name of the referenced object.
    policy : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderConfigRefPolicy, default is Undefined, optional
        policy
    """


    name: str

    policy?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderConfigRefPolicy


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderConfigRefPolicy:
    """
    Policies for referencing.

    Attributes
    ----------
    resolution : str, default is "Required", optional
        Resolution specifies whether resolution of this reference is required. The default is 'Required', which means the reconcile will fail if the reference cannot be resolved. 'Optional' means this reference will be a no-op if it cannot be resolved.
    resolve : str, default is Undefined, optional
        Resolve specifies when this reference should be resolved. The default is 'IfNotPresent', which will attempt to resolve the reference only when the corresponding field is not present. Use 'Always' to resolve the reference on every reconcile.
    """


    resolution?: "Required" | "Optional" = "Required"

    resolve?: "Always" | "IfNotPresent"


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderRef:
    """
    ProviderReference specifies the provider that will be used to create, observe, update, and delete this managed resource. Deprecated: Please use ProviderConfigReference, i.e. `providerConfigRef`

    Attributes
    ----------
    name : str, default is Undefined, required
        Name of the referenced object.
    policy : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderRefPolicy, default is Undefined, optional
        policy
    """


    name: str

    policy?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderRefPolicy


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecProviderRefPolicy:
    """
    Policies for referencing.

    Attributes
    ----------
    resolution : str, default is "Required", optional
        Resolution specifies whether resolution of this reference is required. The default is 'Required', which means the reconcile will fail if the reference cannot be resolved. 'Optional' means this reference will be a no-op if it cannot be resolved.
    resolve : str, default is Undefined, optional
        Resolve specifies when this reference should be resolved. The default is 'IfNotPresent', which will attempt to resolve the reference only when the corresponding field is not present. Use 'Always' to resolve the reference on every reconcile.
    """


    resolution?: "Required" | "Optional" = "Required"

    resolve?: "Always" | "IfNotPresent"


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsTo:
    """
    PublishConnectionDetailsTo specifies the connection secret config which contains a name, metadata and a reference to secret store config to which any connection details for this managed resource should be written. Connection details frequently include the endpoint, username, and password required to connect to the managed resource.

    Attributes
    ----------
    configRef : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToConfigRef, default is Undefined, optional
        config ref
    metadata : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToMetadata, default is Undefined, optional
        metadata
    name : str, default is Undefined, required
        Name is the name of the connection secret.
    """


    configRef?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToConfigRef

    metadata?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToMetadata

    name: str


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToConfigRef:
    """
    SecretStoreConfigRef specifies which secret store config should be used for this ConnectionSecret.

    Attributes
    ----------
    name : str, default is Undefined, required
        Name of the referenced object.
    policy : PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToConfigRefPolicy, default is Undefined, optional
        policy
    """


    name: str

    policy?: PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToConfigRefPolicy


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToConfigRefPolicy:
    """
    Policies for referencing.

    Attributes
    ----------
    resolution : str, default is "Required", optional
        Resolution specifies whether resolution of this reference is required. The default is 'Required', which means the reconcile will fail if the reference cannot be resolved. 'Optional' means this reference will be a no-op if it cannot be resolved.
    resolve : str, default is Undefined, optional
        Resolve specifies when this reference should be resolved. The default is 'IfNotPresent', which will attempt to resolve the reference only when the corresponding field is not present. Use 'Always' to resolve the reference on every reconcile.
    """


    resolution?: "Required" | "Optional" = "Required"

    resolve?: "Always" | "IfNotPresent"


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecPublishConnectionDetailsToMetadata:
    """
    Metadata is the metadata for connection secret.

    Attributes
    ----------
    annotations : {str:str}, default is Undefined, optional
        Annotations are the annotations to be added to connection secret. - For Kubernetes secrets, this will be used as "metadata.annotations". - It is up to Secret Store implementation for others store types.
    labels : {str:str}, default is Undefined, optional
        Labels are the labels/tags to be added to connection secret. - For Kubernetes secrets, this will be used as "metadata.labels". - It is up to Secret Store implementation for others store types.
    $type : str, default is Undefined, optional
        Type is the SecretType for the connection secret. - Only valid for Kubernetes Secret Stores.
    """


    annotations?: {str:str}

    labels?: {str:str}

    $type?: str


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecWriteConnectionSecretToRef:
    """
    WriteConnectionSecretToReference specifies the namespace and name of a Secret to which any connection details for this managed resource should be written. Connection details frequently include the endpoint, username, and password required to connect to the managed resource. This field is planned to be replaced in a future release in favor of PublishConnectionDetailsTo. Currently, both could be set independently and connection details would be published to both without affecting each other.

    Attributes
    ----------
    name : str, default is Undefined, required
        Name of the secret.
    namespace : str, default is Undefined, required
        Namespace of the secret.
    """


    name: str

    namespace: str


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseStatus:
    """
    A DatabaseStatus represents the observed state of a Database.

    Attributes
    ----------
    conditions : [PostgresqlSQLCrossplaneIoV1alpha1DatabaseStatusConditionsItems0], default is Undefined, optional
        Conditions of the resource.
    """


    conditions?: [PostgresqlSQLCrossplaneIoV1alpha1DatabaseStatusConditionsItems0]


schema PostgresqlSQLCrossplaneIoV1alpha1DatabaseStatusConditionsItems0:
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


