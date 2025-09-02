import file

import o11y_mimir_base
import charts.mimir
import cluster
import konfig.models.frontend.secret
import konfig.utils

_baseValues = o11y_mimir_base.app.charts.mimir.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

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
