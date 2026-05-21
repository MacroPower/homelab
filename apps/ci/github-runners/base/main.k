import file

import konfig.models.frontend
import konfig.models.frontend.secret
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

    charts.gha_runner_scale_set = runner_set.Chart {
        releaseName = "dagger"
        values = _values
    }
}
