import file

import konfig.models.frontend.secret
import konfig.files
import konfig.objects

import o11y_loki_base
import charts.loki

_baseValues = o11y_loki_base.app.charts.loki.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# The real S3 backend (seaweedfs) is offline locally, so point every remoteRef
# at the fake "dummy" key the local provider answers. Loki will start but object
# storage reads/writes fail until a real S3 endpoint exists (degraded).
_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        S3_ACCESS_KEY = {
            remoteRef.key = "dummy"
        }
        S3_SECRET_KEY = {
            remoteRef.key = "dummy"
        }
    }
}

app = o11y_loki_base.app | {
    externalSecrets.s3Config = _s3Config

    charts.loki.values = _values | loki.Values {
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
