import charts.external_secrets.api.v1beta1 as externalsecretsv1beta1
import models.frontend.common

schema ExternalSecret(common.Metadata):
    """
    ExternalSecret is a reference to an external secret stored in a secret store.

    Attributes
    ----------
    secretStoreRef: ExternalSecretsIoV1beta1ExternalSecretSpecSecretStoreRef, default is Undefined, optional
        secret store ref
    refreshInterval: str, default is "1h", optional
        RefreshInterval is the amount of time before the values are read again from the SecretStore provider
        Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h"
        May be set to zero to fetch and create it once. Defaults to 1h.
    data: {str:ExternalSecretData}, default is Undefined, optional
        Data defines the connection between the Kubernetes Secret keys and the Provider data
    target: ExternalSecretsIoV1beta1ExternalSecretSpecTarget, default is Undefined, optional
        target
    getSecretKeyRef: (str) -> {str:}
        Returns the `secretKeyRef` for the given `data` key.
        If the `data` key does not exist, it returns an error.
    """
    secretStoreRef?: externalsecretsv1beta1.ExternalSecretsIoV1beta1ExternalSecretSpecSecretStoreRef
    refreshInterval?: str = "1h"
    data?: {str:ExternalSecretData}
    target?: externalsecretsv1beta1.ExternalSecretsIoV1beta1ExternalSecretSpecTarget

    getSecretKeyRef: (str) -> common.SecretKeyReference = lambda dataKey: str -> common.SecretKeyReference {
        assert data[dataKey], "referenced data does not exist"
        {
            name = name
            key = data[dataKey]?.secretKey or dataKey
        }
    }

    getSecretKeyEnvRef: (str) -> {str:} = lambda dataKey: str {
        {
            secretKeyRef = getSecretKeyRef(dataKey)
        }
    }

schema ExternalSecretData:
    """
    ExternalSecretData defines the connection between the Kubernetes Secret key (spec.data.<key>) and the Provider data.

    Attributes
    ----------
    secretKey: str, default is Undefined, required
        SecretKey defines the key in which the controller stores the value. This is the key in the Kind=Secret
    remoteRef: ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0RemoteRef, default is Undefined, required
        remote ref
    sourceRef: ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRef, default is Undefined, optional
        source ref
    """
    secretKey?: str
    remoteRef?: externalsecretsv1beta1.ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0RemoteRef
    sourceRef?: ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRef

schema ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRef:
    """
    SourceRef allows you to override the source
    from which the value will be pulled.

    Attributes
    ----------
    generatorRef : ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRefGeneratorRef, default is Undefined, optional
        generator ref
    storeRef : ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRefStoreRef, default is Undefined, optional
        store ref
    """
    generatorRef?: ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRefGeneratorRef

schema ExternalSecretsIoV1beta1ExternalSecretSpecDataItems0SourceRefGeneratorRef:
    """
    GeneratorRef points to a generator custom resource.

    Deprecated: The generatorRef is not implemented in .data[].
    this will be removed with v1.

    Attributes
    ----------
    apiVersion : str, default is "generators.external-secrets.io/v1alpha1", optional
        Specify the apiVersion of the generator resource
    kind : str, default is "ClusterGenerator", optional
        Specify the Kind of the generator resource
    name : str, default is Undefined, required
        Specify the name of the generator resource
    """
    apiVersion?: str = "generators.external-secrets.io/v1alpha1"
    kind: str = "ClusterGenerator"
    name: str
