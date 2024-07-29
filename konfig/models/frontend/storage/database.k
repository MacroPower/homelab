import models.frontend.common
import crossplane_provider_sql.postgres.v1alpha1 as postgresv1alpha1

schema PostgresDatabase(common.Metadata):
    """
    Postgres database.
    """
    deletionPolicy?: "Orphan" | "Delete" = "Delete"
    ownerPasswordSecretRef?: common.SecretKeyReference
    ownerRole?: postgresv1alpha1.PostgresqlSQLCrossplaneIoV1alpha1RoleSpecForProvider = {
        privileges.login = True
    }
    database?: postgresv1alpha1.PostgresqlSQLCrossplaneIoV1alpha1DatabaseSpecForProvider = {
        owner = name
        encoding = "utf8"
    }
    providerConfigName?: str
