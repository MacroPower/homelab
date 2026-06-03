import file

import konfig.files
import konfig.objects

import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

import ci_github_runners_base
import charts.gha_runner_scale_set as runner_set

_baseValues = ci_github_runners_base.app.charts.gha_runner_scale_set.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Inherit the real github-runners app (network policies included; they resolve fine
# locally), then apply Docker-safe deltas:
#   - clear the mayastor nodeSelector on the runner pod (via values.yaml merge),
#   - point the github-runner-credentials ExternalSecret remoteRefs at "dummy" so the
#     fake secret store answers them (no real GitHub App auth offline -> degraded).
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
    externalSecrets.githubRunnerCredentials.data = {
        github_app_id.remoteRef.key = "dummy"
        github_app_installation_id.remoteRef.key = "dummy"
        github_app_private_key.remoteRef.key = "dummy"
    }
    charts.gha_runner_scale_set.values = _values | runner_set.Values {}
}
