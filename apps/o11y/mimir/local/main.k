import file

import konfig.models.frontend.secret
import konfig.files
import konfig.objects

import o11y_mimir_base
import charts.mimir
import cluster

_baseValues = o11y_mimir_base.app.charts.mimir.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Point the S3 credential ExternalSecret at the fake provider's "dummy" key so
# the local cluster's fake secret store can answer it (no real Doppler/S3 keys).
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

app = o11y_mimir_base.app | {
    externalSecrets.s3Config = _s3Config

    charts.mimir.values = _values | mimir.Values {
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
        metaMonitoring.serviceMonitor.clusterLabel = cluster.NAME
    }
}
