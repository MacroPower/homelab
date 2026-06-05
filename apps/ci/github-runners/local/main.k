import file

import konfig.files
import konfig.objects

import ci_github_runners_base
import charts.gha_runner_scale_set as runner_set

_baseValues = ci_github_runners_base.app.charts.gha_runner_scale_set.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Inherit the real github-runners app (network policies included; they resolve fine
# locally), then apply Docker-safe deltas:
#   - clear the mayastor nodeSelector on the runner pod (via values.yaml merge),
#   - point the github-runner-credentials ExternalSecret remoteRefs at "dummy" so
#     the fake secret store answers them. The controller then fails one step
#     before GitHub auth, at createRunnerScaleSet parsing github_app_id="dummy"
#     as an integer, so no listener is ever created (degraded, contained).
app = ci_github_runners_base.app | {
    externalSecrets.githubRunnerCredentials.data = {
        github_app_id.remoteRef.key = "dummy"
        github_app_installation_id.remoteRef.key = "dummy"
        github_app_private_key.remoteRef.key = "dummy"
    }
    charts.gha_runner_scale_set.values = _values | runner_set.Values {}
}
