import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt
import konfig.files

import ci_shared
import charts.gha_runner_scale_set as runner_set

_values = files.read_yaml(file.current(), "values.yaml")

_githubRunnerCreds = secret.ExternalSecret {
    name = "github-runner-credentials"
    data = {
        github_app_id = {
            remoteRef.key = "GITHUB_RUNNER_APP_ID"
        }
        github_app_installation_id = {
            remoteRef.key = "GITHUB_RUNNER_APP_INSTALLATION_ID"
        }
        github_app_private_key = {
            remoteRef.key = "GITHUB_RUNNER_APP_PRIVATE_KEY"
        }
    }
}

app = frontend.App {
    name = "github-runners"
    tenantName = ci_shared.tenant.name
    secretStore = ci_shared.shared.secretStores.default.name

    externalSecrets.githubRunnerCredentials = _githubRunnerCreds

    serviceAccounts.githubRunner = {
        name = "github-runner"
    }

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

    charts.gha_runner_scale_set = runner_set.Chart {
        releaseName = "dagger"
        values = _values
    }
}
