import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import o11y_shared
import charts.loki

_values = files.read_yaml(file.current(), "values.yaml")

# Object-storage credentials. The remoteRef keys are cluster-specific and set by
# each overlay; the secret name, mapped keys, and env wiring are shared.
_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        S3_ACCESS_KEY = {
            remoteRef.key = ""
        }
        S3_SECRET_KEY = {
            remoteRef.key = ""
        }
    }
}

app = frontend.App {
    name = "loki"
    tenantName = o11y_shared.tenant.name

    secretStore = o11y_shared.shared.secretStores.default.name

    externalSecrets.s3Config = _s3Config

    charts.loki = loki.Chart {
        values: _values | loki.Values {
            global.extraEnv: [
                {
                    name = "S3_ACCESS_KEY"
                    valueFrom = _s3Config.getSecretKeyEnvRef("S3_ACCESS_KEY")
                }
                {
                    name = "S3_SECRET_KEY"
                    valueFrom = _s3Config.getSecretKeyEnvRef("S3_SECRET_KEY")
                }
            ]
        }
    }
}
