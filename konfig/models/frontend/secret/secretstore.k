import models.frontend.common
import external_secrets.v1beta1 as externalsecretsv1beta1

schema ClusterSecretStore(common.Metadata):
    provider?: externalsecretsv1beta1.ExternalSecretsIoV1beta1ClusterSecretStoreSpecProvider

schema SecretStore(common.Metadata):
    provider?: externalsecretsv1beta1.ExternalSecretsIoV1beta1SecretStoreSpecProvider

schema NamespaceSecretStore(common.Metadata):
    remoteNamespace: str
    name?: str = "{}-namespace".format(remoteNamespace)
    serviceAccountName?: str = name

    getRef: () -> externalsecretsv1beta1.ExternalSecretsIoV1beta1ExternalSecretSpecSecretStoreRef = lambda -> externalsecretsv1beta1.ExternalSecretsIoV1beta1ExternalSecretSpecSecretStoreRef {
        {
            kind = "SecretStore"
            name = name
        }
    }
