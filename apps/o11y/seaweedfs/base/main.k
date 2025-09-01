import file
import json

import o11y
import charts.seaweedfs
import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        MIMIR_S3_ACCESS_KEY = {}
        MIMIR_S3_SECRET_KEY = {}
    }
    target.template.metadata.labels: {
        "app.kubernetes.io/name" = "seaweedfs"
        "app.kubernetes.io/component" = "s3"
    }
    target.template.data: {
        seaweedfs_s3_config = json.encode({
            identities = [
                {
                    name = "mimir"
                    credentials = [
                        {
                            accessKey = "{{.MIMIR_S3_ACCESS_KEY}}"
                            secretKey = "{{.MIMIR_S3_SECRET_KEY}}"
                        }
                    ]
                    actions = [
                        "Read:mimir-blocks"
                        "Write:mimir-blocks"
                        "Admin:mimir-blocks"
                        "Read:mimir-alertmanager"
                        "Write:mimir-alertmanager"
                        "Admin:mimir-alertmanager"
                        "Read:mimir-ruler"
                        "Write:mimir-ruler"
                        "Admin:mimir-ruler"
                    ]
                }
            ]
        }, indent=2)
    }
}

app = frontend.App {
    name = "seaweedfs"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    externalSecrets.s3Config = _s3Config

    charts.seaweedfs = seaweedfs.Chart {
        values: _values | seaweedfs.Values {
            filer.s3.existingConfigSecret = _s3Config.name
        }
    }
}
