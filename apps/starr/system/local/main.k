import starr_system_base

# Docker-safe local overlay for the starr CNPG database stack.
#
# - The CloudNativePG `Cluster` is collapsed to a single instance: a quorum of
#   three cannot schedule on the one tald node, the zone topologySpreadConstraint
#   strands replicas, and the `openebs-zfs-postgres` StorageClass does not exist
#   locally (only `openebs-hostpath` does).
# - The three postgres-credentials ExternalSecrets read real Doppler keys; the
#   offline fake ClusterSecretStore only serves the constant key "dummy", so each
#   data key's remoteRef is repointed at "dummy" to resolve offline.
app = starr_system_base.app | {
    extraResources.pgCluster.spec: {
        instances = 1
        storage.storageClass = "openebs-hostpath"
        topologySpreadConstraints = []
    }

    externalSecrets: {
        sonarrCreds.data.SONARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
        radarrCreds.data.RADARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
        prowlarrCreds.data.PROWLARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
    }
}
