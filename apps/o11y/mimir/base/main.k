import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import o11y_shared
import charts.mimir

_values = files.read_yaml(file.current(), "values.yaml")

_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        S3_ACCESS_KEY = {
            remoteRef.key = "MIMIR_S3_ACCESS_KEY"
        }
        S3_SECRET_KEY = {
            remoteRef.key = "MIMIR_S3_SECRET_KEY"
        }
    }
}

app = frontend.App {
    name = "mimir"
    tenantName = o11y_shared.tenant.name

    secretStore = o11y_shared.shared.secretStores.default.name

    externalSecrets.s3Config = _s3Config

    charts.mimir = mimir.Chart {
        values: _values | mimir.Values {
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
