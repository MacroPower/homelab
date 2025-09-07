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

_prowlarrCreds = secret.ExternalSecret {
    name = "prowlarr-postgres-credentials"
    data: {
        PROWLARR_POSTGRES_PASSWORD = {}
    }
    target.template: {
        metadata.labels = cnpgReload
        data = {
            username = "prowlarr"
            password = "{{.PROWLARR_POSTGRES_PASSWORD}}"
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

prowlarrRole = cnpgRole {
    name = "prowlarr"
    login = True
    passwordSecret.name = _prowlarrCreds.name
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
                prowlarrRole
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

_prowlarrMainDatabase = cnpgv1.Database {
    metadata.name = "prowlarr-main"
    spec: {
        name = metadata.name
        owner = prowlarrRole.name
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
        prowlarrCreds = _prowlarrCreds
    }

    extraResources: {
        pgCluster = _pgCluster
        sonarrMainDatabase = _sonarrMainDatabase
        radarrMainDatabase = _radarrMainDatabase
        prowlarrMainDatabase = _prowlarrMainDatabase
    }
}
