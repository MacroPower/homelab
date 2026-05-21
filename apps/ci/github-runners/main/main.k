import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

import ci_github_runners_base

app = ci_github_runners_base.app | {
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
        daggerEngineEgress = networkpolicy.NetworkPolicy {
            name = "dagger-engine-egress"
            egress = [{
                toEndpoints = [{
                    matchLabels = {
                        "io.kubernetes.pod.namespace" = "ci-dagger-engine"
                        "name" = "dagger-helm-engine"
                    }
                }]
                toPorts = [{
                    ports = [{
                        port = "8989"
                        protocol = "TCP"
                    }]
                }]
            }]
        }
        githubEgress = networkpolicy.NetworkPolicy {
            name = "github-egress"
            egress = [{
                toFQDNs = [
                    {matchName = "github.com"}
                    {matchName = "api.github.com"}
                    {matchName = "codeload.github.com"}
                    {matchName = "objects.githubusercontent.com"}
                    {matchPattern = "*.actions.githubusercontent.com"}
                    {matchName = "ghcr.io"}
                    {matchPattern = "*.pkg-containers.githubusercontent.com"}
                ]
            }]
        }
    }
}
