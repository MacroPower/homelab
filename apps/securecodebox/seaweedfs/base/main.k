import file
import json

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import securecodebox
import charts.seaweedfs

_values = files.read_yaml(file.current(), "values.yaml")

# TODO: Needs to reload seaweedfs-filer
_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        SECURECODEBOX_S3_ACCESS_KEY = {}
        SECURECODEBOX_S3_SECRET_KEY = {}
    }
    target.template.metadata.labels: {
        "app.kubernetes.io/name" = "seaweedfs"
        "app.kubernetes.io/component" = "s3"
    }
    target.template.data: {
        seaweedfs_s3_config = json.encode({
            identities = [
                {
                    name = "securecodebox"
                    credentials = [
                        {
                            accessKey = "{{.SECURECODEBOX_S3_ACCESS_KEY}}"
                            secretKey = "{{.SECURECODEBOX_S3_SECRET_KEY}}"
                        }
                    ]
                    actions = [
                        "Read:securecodebox"
                        "Write:securecodebox"
                        "Admin:securecodebox"
                    ]
                }
            ]
        }, indent=2)
    }
}

app = frontend.App {
    name = "seaweedfs"
    tenantName = securecodebox.tenant.name

    secretStore = securecodebox.shared.secretStores.default.name

    externalSecrets.s3Config = _s3Config

    charts.seaweedfs = seaweedfs.Chart {
        values: _values | seaweedfs.Values {
            filer.s3.existingConfigSecret = _s3Config.name
        }
    }
}
