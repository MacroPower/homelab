import starr_system_base

# Docker-safe local overlay for the starr CNPG database stack.
#
# - The CloudNativePG `Cluster` is collapsed to a single instance: a quorum of
#   three cannot schedule on the one tald node, and the `openebs-zfs-postgres`
#   StorageClass does not exist locally (only `openebs-hostpath` does).
# - The base zone topologySpreadConstraint is dropped from the rendered spec
#   entirely (Undefined, not `[]`): the tald node has no
#   topology.kubernetes.io/zone label, so the DoNotSchedule constraint would
#   leave the pod unschedulable, while an explicit empty list makes CNPG restart
#   the primary forever ("original and target PodSpec differ in
#   topology-spread-constraints", comparing [] against the running pod's nil).
# - The three postgres-credentials ExternalSecrets read real Doppler keys; the
#   offline fake ClusterSecretStore only serves the constant key "dummy", so each
#   data key's remoteRef is repointed at "dummy" to resolve offline.
app = starr_system_base.app | {
    extraResources.pgCluster.spec: {
        instances = 1
        storage.storageClass = "openebs-hostpath"
        topologySpreadConstraints = Undefined
    }

    externalSecrets: {
        sonarrCreds.data.SONARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
        radarrCreds.data.RADARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
        prowlarrCreds.data.PROWLARR_POSTGRES_PASSWORD.remoteRef.key = "dummy"
    }
}
