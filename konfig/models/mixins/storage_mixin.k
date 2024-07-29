import models.utils
import models.resource
import models.protocol
import crossplane_provider_sql.postgres.v1alpha1 as postgresv1alpha1

mixin PostgresDatabaseMixin for protocol.AppProtocol:
    if config.postgresDatabases:
        kubernetes: resource.ResourceMapping {
            PostgresDatabaseRoles = [postgresv1alpha1.Role {
                metadata: utils.MetadataBuilder(_c)
                spec: {
                    deletionPolicy: _c.deletionPolicy
                    forProvider: _c.ownerRole | {
                        passwordSecretRef: {
                            name: _c.ownerPasswordSecretRef.name
                            key: _c.ownerPasswordSecretRef.key
                            namespace: config.namespace
                        }
                    }
                    providerConfigRef: {
                        name = _c.providerConfigName
                    }
                }
            } for _i, _c in config.postgresDatabases]
            PostgresDatabases = [postgresv1alpha1.Database {
                metadata: utils.MetadataBuilder(_c)
                spec: {
                    deletionPolicy: _c.deletionPolicy
                    forProvider: _c.database
                    providerConfigRef: {
                        name = _c.providerConfigName
                    }
                }
            } for _i, _c in config.postgresDatabases]
        }
