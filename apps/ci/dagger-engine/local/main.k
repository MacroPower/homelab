import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

import ci_dagger_engine_base

_enginePort = 8989

_engineService = {
    apiVersion = "v1"
    kind = "Service"
    metadata.name = "dagger-engine"
    spec = {
        type = "ClusterIP"
        internalTrafficPolicy = "Local"
        selector.name = "dagger-helm-engine"
        ports = [{
            name = "dagger"
            port = _enginePort
            targetPort = "dagger"
            protocol = "TCP"
        }]
    }
}

# Local (Talos-in-Docker) overlay. Mirrors the main overlay (extra ClusterIP
# Service + network policies) and clears the mayastor nodeSelector so the engine
# DaemonSet schedules on the single tald node. The ephemeral data volume already
# uses openebs-hostpath, the only StorageClass available locally.
app = ci_dagger_engine_base.app | {
    charts.dagger_helm.values.engine.nodeSelector = {}

    extraResources.service = _engineService

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        runnerIngress = networkpolicy.NetworkPolicy {
            name = "runner-ingress"
            ingress = [{
                fromEndpoints = [{
                    matchLabels = {
                        "io.kubernetes.pod.namespace" = "ci-github-runners"
                    }
                }]
                toPorts = [{
                    ports = [{
                        port = "${_enginePort}"
                        protocol = "TCP"
                    }]
                }]
            }]
        }
        registryEgress = networkpolicy.NetworkPolicy {
            name = "registry-egress"
            egress = [{
                toFQDNs = [
                    {matchName = "registry.dagger.io"}
                    {matchName = "registry-1.docker.io"}
                    {matchPattern = "*.docker.io"}
                    {matchName = "ghcr.io"}
                    {matchPattern = "*.pkg-containers.githubusercontent.com"}
                ]
            }]
        }
    }
}
