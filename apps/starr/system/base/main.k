import konfig.models.frontend
import konfig.models.frontend.secret

import starr
import charts.cloudnative_pg.api.v1 as cnpgv1

cnpgRole = cnpgv1.PostgresqlCnpgIoV1ClusterSpecManagedRolesItems0

cnpgReload = { "cnpg.io/reload": "true" }

_sonarrCreds = secret.ExternalSecret {
    name = "sonarr-postgres-credentials"
    data: {
        SONARR_POSTGRES_PASSWORD = {}
    }
    target.template: {
        metadata.labels = cnpgReload
        data = {
            username = "sonarr"
            password = "{{.SONARR_POSTGRES_PASSWORD}}"
        }
    }
}

_radarrCreds = secret.ExternalSecret {
    name = "radarr-postgres-credentials"
    data: {
        RADARR_POSTGRES_PASSWORD = {}
    }
    target.template: {
        metadata.labels = cnpgReload
        data = {
            username = "radarr"
            password = "{{.RADARR_POSTGRES_PASSWORD}}"
        }
    }
}

sonarrRole = cnpgRole {
    name = "sonarr"
    login = True
    passwordSecret.name = _sonarrCreds.name
}

radarrRole = cnpgRole {
    name = "radarr"
    login = True
    passwordSecret.name = _radarrCreds.name
}

_pgCluster = cnpgv1.Cluster{
    metadata: {
        name = "starr-postgres"
    }
    spec: {
        managed: {
            roles = [
                sonarrRole
                radarrRole
            ]
        }
        instances = 3
        # https://github.com/cloudnative-pg/postgres-containers
        imageName = "ghcr.io/cloudnative-pg/postgresql:17.6-standard-bookworm"
        storage = {
            storageClass = "openebs-zfs-postgres"
            size = "50Gi"
        }
        topologySpreadConstraints = [
            {
                labelSelector.matchLabels = {
                    "cnpg.io/cluster" = "starr-postgres"
                }
                maxSkew = 1
                topologyKey = "topology.kubernetes.io/zone"
                whenUnsatisfiable = "DoNotSchedule"
            }
        ]
    }
}

_sonarrMainDatabase = cnpgv1.Database {
    metadata.name = "sonarr-main"
    spec: {
        name = metadata.name
        owner = sonarrRole.name
        cluster.name = _pgCluster.metadata.name
    }
}

_radarrMainDatabase = cnpgv1.Database {
    metadata.name = "radarr-main"
    spec: {
        name = metadata.name
        owner = radarrRole.name
        cluster.name = _pgCluster.metadata.name
    }
}

app = frontend.App {
    name = "system"
    tenantName = starr.tenant.name
    secretStore = starr.shared.secretStores.default.name

    externalSecrets: {
        sonarrCreds = _sonarrCreds
        radarrCreds = _radarrCreds
    }

    extraResources: {
        pgCluster = _pgCluster
        sonarrMainDatabase = _sonarrMainDatabase
        radarrMainDatabase = _radarrMainDatabase
    }
}
