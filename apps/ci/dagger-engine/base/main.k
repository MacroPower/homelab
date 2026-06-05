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
                # Registries 307-redirect blob downloads to CDN hosts, which
                # need allowing alongside the registry API hosts themselves:
                # docker.io blobs come from production.cloudfront.docker.com,
                # ghcr.io blobs from the BARE pkg-containers.githubusercontent.com
                # (Cilium's "*." patterns require a subdomain, so the bare host
                # needs its own matchName), and quay.io blobs from cdn0X.quay.io.
                toFQDNs = [
                    {matchName = "registry.dagger.io"}
                    {matchName = "registry-1.docker.io"}
                    {matchPattern = "*.docker.io"}
                    {matchName = "production.cloudfront.docker.com"}
                    {matchName = "ghcr.io"}
                    {matchName = "pkg-containers.githubusercontent.com"}
                    {matchPattern = "*.pkg-containers.githubusercontent.com"}
                    {matchName = "quay.io"}
                    {matchPattern = "cdn*.quay.io"}
                ]
            }]
        }
    }
}
