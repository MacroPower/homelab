import file

import charts.external_secrets
import charts.external_secrets.api.v1alpha1 as externalsecretsv1alpha1
import external
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app: frontend.App {
    name = "secrets"
    tenantName = external.tenant.name

    charts.external_secrets = external_secrets.Chart {
        values: _values | external_secrets.Values {}
    }

    extraResources.alphanumericPasswordGenerator = externalsecretsv1alpha1.ClusterGenerator {
        metadata: {
            name = "alphanumeric-password"
        }
        spec: {
            kind = "Password"
            generator.passwordSpec = {
                length = 32
                symbolCharacters = ""
            }
        }
    }
}
