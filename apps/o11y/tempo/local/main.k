import file

import konfig.models.frontend.secret
import konfig.files
import konfig.objects

import o11y_tempo_base
import charts.tempo

_baseValues = o11y_tempo_base.app.charts.tempo.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Offline: point the s3-config ExternalSecret at the fake provider's "dummy"
# key for every data entry so the local secret store can answer it. The base S3
# endpoint targets the local o11y/seaweedfs overlay, whose single identity uses
# the same literal dummy/dummy credentials, so traces persist for real when
# that heavy stack is enabled. Tempo validates the object store at startup
# (ListObjects) and crashes without it -- enable o11y/seaweedfs alongside.
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

app = o11y_tempo_base.app | {
    externalSecrets.s3Config = _s3Config

    charts.tempo.values = _values | tempo.Values {
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
