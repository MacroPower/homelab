import ci_dagger_engine_base

# Local (Talos-in-Docker) overlay. Clears the mayastor nodeSelector so the
# engine DaemonSet schedules on the single tald node. The ephemeral data volume
# already uses openebs-hostpath, the only StorageClass available locally.
app = ci_dagger_engine_base.app | {
    charts.dagger_helm.values.engine.nodeSelector = {}
}
