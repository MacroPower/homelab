import k8s.api.core.v1
import models.utils
import models.resource
import models.protocol
import external_secrets.v1beta1 as externalsecretsv1beta1

mixin SecretMixin for protocol.AppProtocol:
    if config.secrets:
        kubernetes: resource.ResourceMapping {
            Secret = [v1.Secret {
                metadata: utils.MetadataBuilder(config | _c)
                data = _s?.data
                stringData = _s?.stringData
                type = _s?.type
            } for _i, _s in config.secrets]
        }

mixin SecretStoreMixin for protocol.AppProtocol:
    if config.secretStores:
        kubernetes: resource.ResourceMapping {
            SecretStore = [externalsecretsv1beta1.SecretStore {
                metadata = utils.MetadataBuilder(config | _c)
                spec.provider = _c.provider
            } for _i, _c in config.secretStores]
        }

mixin ClusterSecretStoreMixin for protocol.TenantProtocol:
    if config.secretStores:
        kubernetes: resource.ResourceMapping {
            ClusterSecretStore = [externalsecretsv1beta1.ClusterSecretStore {
                metadata = utils.MetadataBuilder(config | _c)
                spec.conditions = [{
                    namespaceRegexes = ["{}-.+".format(_c.name)]
                }]
                spec.provider = _c.provider
            } for _i, _c in config.secretStores]
        }

mixin ExternalSecretMixin for protocol.AppProtocol:
    if config.externalSecrets:
        kubernetes: resource.ResourceMapping {
            ExternalSecret = [externalsecretsv1beta1.ExternalSecret {
                metadata: utils.MetadataBuilder(config | _c)
                spec: {
                    if _c.secretStoreRef:
                        secretStoreRef = _c.secretStoreRef
                    else:
                        secretStoreRef: {
                            kind: "ClusterSecretStore"
                            name: config.secretStore
                        }
                    data: [{
                            secretKey: _i or _d.secretKey
                            if _d?.remoteRef:
                                remoteRef: _d?.remoteRef
                            else:
                                remoteRef.key: secretKey
                            sourceRef: _d?.sourceRef
                    } for _i, _d in _c.data]
                    refreshInterval: _c.refreshInterval
                    target: _c.target
                }
            } for _i, _c in config.externalSecrets]
        }

mixin NamespaceSecretStoreMixin for protocol.AppProtocol:
    if config.namespaceSecretStores:
        kubernetes: resource.ResourceMapping {
            NamespaceSecretStoreServiceAccounts = [v1.ServiceAccount {
                metadata: utils.MetadataBuilder(config | _c)
            } for _i, _c in config.namespaceSecretStores]
            NamespaceSecretStores = [externalsecretsv1beta1.SecretStore {
                metadata: utils.MetadataBuilder(config | _c)
                spec.provider.kubernetes: {
                    remoteNamespace = _c.remoteNamespace
                    server.caProvider: {
                        type = "ConfigMap"
                        name = "kube-root-ca.crt"
                        key = "ca.crt"
                    }
                    auth.serviceAccount.name = _c.serviceAccountName
                }
            } for _i, _c in config.namespaceSecretStores]
        }
