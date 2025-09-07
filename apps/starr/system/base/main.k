import starr
import charts.cloudnative_pg.api.v1 as cnpgv1
import konfig.models.frontend

_pgCluster = cnpgv1.Cluster{
    metadata: {
        name = "starr-postgres"
    }
    spec: {
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

app = frontend.App {
    name = "system"
    tenantName = starr.tenant.name

    extraResources: {
        pgCluster = _pgCluster
    }
}
