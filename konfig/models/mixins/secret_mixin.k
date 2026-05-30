import charts.external_secrets.api.v1 as externalsecretsv1
import k8s.api.core.v1
import models.metadata as kmd
import models.protocol
import models.resource
import models.utils

mixin SecretMixin for protocol.AppProtocol:
    if config.secrets:
        kubernetes: resource.ResourceMapping {
            Secret = [v1.Secret {
                metadata: utils.MetadataBuilder(config | _c)
                data = _c?.data
                stringData = _c?.stringData
                type = _c?.type
            } for _i, _c in config.secrets]
        }

# `fakeSecretStores` is honored only for the shared-tier ClusterSecretStores
# (ClusterSecretStoreMixin below). App-level SecretStores and the in-cluster
# NamespaceSecretStores are left real: no offline-deployed app sets them, and the
# namespace store's `kubernetes` provider has no external backend to fake.
mixin SecretStoreMixin for protocol.AppProtocol:
    if config.secretStores:
        kubernetes: resource.ResourceMapping {
            SecretStore = [externalsecretsv1.SecretStore {
                metadata = utils.MetadataBuilder(config | _c)
                spec.provider = _c.provider
            } for _i, _c in config.secretStores]
        }

mixin ClusterSecretStoreMixin for protocol.TenantProtocol:
    if config.secretStores:
        kubernetes: resource.ResourceMapping {
            ClusterSecretStore = [externalsecretsv1.ClusterSecretStore {
                metadata = utils.MetadataBuilder(config | _c)
                # On offline clusters (fakeSecretStores) the store serves a
                # constant dummy value instead of a real backend, so dependent
                # ExternalSecrets resolve -- the enumerated keys are the offline limit.
                spec.conditions = [{
                    namespaceRegexes = ["{}-.+".format(_c.name)]
                }]
                if kmd.context.fakeSecretStores:
                    spec.provider.fake.data = [{key = "dummy", value = "dummy"}]
                else:
                    spec.provider = _c.provider
            } for _i, _c in config.secretStores]
        }

mixin ExternalSecretMixin for protocol.AppProtocol:
    if config.externalSecrets:
        kubernetes: resource.ResourceMapping {
            ExternalSecret = [externalsecretsv1.ExternalSecret {
                metadata: utils.MetadataBuilder(config | _c)
                spec: {
                    if _c.secretStoreRef:
                        secretStoreRef = _c.secretStoreRef
                    else:
                        secretStoreRef: {
                            kind: "ClusterSecretStore"
                            name: config.secretStore
                        }
                    data: [
                        {
                            secretKey: _i or _d.secretKey
                            if _d?.remoteRef:
                                remoteRef: _d?.remoteRef
                            else:
                                remoteRef.key: secretKey
                        }
                        for _i, _d in _c.data if not _d?.sourceRef
                    ]
                    dataFrom: [
                        {
                            sourceRef.generatorRef: {
                                apiVersion = _d?.sourceRef.generatorRef?.apiVersion or "generators.external-secrets.io/v1alpha1"
                                kind = _d?.sourceRef.generatorRef?.kind or "ClusterGenerator"
                                name = _d?.sourceRef.generatorRef.name
                            }
                            rewrite: [
                                {
                                    regexp.source = "password"
                                    regexp.target = _i or _d.secretKey
                                }
                            ]
                        }
                        for _i, _d in _c.data if _d?.sourceRef
                    ]
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
            NamespaceSecretStores = [externalsecretsv1.SecretStore {
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
