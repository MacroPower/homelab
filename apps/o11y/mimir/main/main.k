import file
import json
import yaml

import o11y_mimir_base
import charts.mimir
import charts.seaweedfs
import konfig.models.frontend.secret
import konfig.utils

_baseValues = o11y_mimir_base.app.charts.mimir.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

_s3Config = secret.ExternalSecret {
    name = "s3-config"
    refreshInterval = "0"
    data: {
        S3_ACCESS_KEY = {
            sourceRef.generatorRef = {
                name = "alphanumeric-password"
            }
        }
        S3_SECRET_KEY = {
            sourceRef.generatorRef = {
                name = "alphanumeric-password"
            }
        }
    }
    target.template.metadata.labels: {
        "app.kubernetes.io/name" = "seaweedfs"
        "app.kubernetes.io/component" = "s3"
    }
    target.template.data: {
        S3_ACCESS_KEY = "{{.S3_ACCESS_KEY}}"
        S3_SECRET_KEY = "{{.S3_SECRET_KEY}}"
        seaweedfs_s3_config = json.encode({
            identities = [
                {
                    name = "mimir"
                    credentials = [
                        {
                            accessKey = "{{.S3_ACCESS_KEY}}"
                            secretKey = "{{.S3_SECRET_KEY}}"
                        }
                    ]
                    actions = ["Read", "Write"]
                }
            ]
        })
    }
}

app = o11y_mimir_base.app | {
    externalSecrets.s3Config = _s3Config

    charts.mimir.values = _values | mimir.Values {
        extraEnv: [
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

    charts.seaweedfs = seaweedfs.Chart {
        values = seaweedfs.Values {
            master.enabled = False
            filer.enabled = False
            volume.enabled = False
            allInOne: {
                enabled = True
                s3.enabled = True
                nodeSelector = yaml.encode({
                    "kubernetes.io/hostname" = "knas01"
                })
                tolerations = yaml.encode([{
                    key = "node-role.kubernetes.io/storage"
                    operator = "Exists"
                }])
                data: {
                    type = "persistentVolumeClaim"
                    size = "1Ti"
                    storageClass = "openebs-hostpath"
                }
            }
            s3: {
                enableAuth = True
                existingConfigSecret = _s3Config.name
            }
        }
    }
}
