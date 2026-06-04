import file

import konfig.models.frontend
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt
import konfig.files

import ci_shared
import charts.dagger_helm as dagger

_values = files.read_yaml(file.current(), "values.yaml")

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

app = frontend.App {
    name = "dagger-engine"
    tenantName = ci_shared.tenant.name

    charts.dagger_helm = dagger.Chart {
        values = _values | dagger.Values {}
    }

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
