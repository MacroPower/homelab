import charts.external_secrets.api.v1 as externalsecretsv1
import models.frontend.common

schema ClusterSecretStore(common.Metadata):
    provider?: externalsecretsv1.ExternalSecretsIoV1ClusterSecretStoreSpecProvider

schema SecretStore(common.Metadata):
    provider?: externalsecretsv1.ExternalSecretsIoV1SecretStoreSpecProvider
    getRef: () -> externalsecretsv1.ExternalSecretsIoV1ExternalSecretSpecSecretStoreRef = lambda -> externalsecretsv1.ExternalSecretsIoV1ExternalSecretSpecSecretStoreRef {
        {
            kind = "SecretStore"
            name = name
        }
    }

schema NamespaceSecretStore(common.Metadata):
    remoteNamespace: str
    name?: str = "{}-namespace".format(remoteNamespace)
    serviceAccountName?: str = name
    getRef: () -> externalsecretsv1.ExternalSecretsIoV1ExternalSecretSpecSecretStoreRef = lambda -> externalsecretsv1.ExternalSecretsIoV1ExternalSecretSpecSecretStoreRef {
        {
            kind = "SecretStore"
            name = name
        }
    }
