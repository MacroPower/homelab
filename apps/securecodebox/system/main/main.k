import file

import konfig.models.frontend.secret
import konfig.files
import konfig.objects

import securecodebox_system_base
import charts.securecodebox

_baseValues = securecodebox_system_base.app.charts.securecodebox.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        S3_ACCESS_KEY = {
            remoteRef.key = "SECURECODEBOX_S3_ACCESS_KEY"
        }
        S3_SECRET_KEY = {
            remoteRef.key = "SECURECODEBOX_S3_SECRET_KEY"
        }
    }
}

app = securecodebox_system_base.app | {
    externalSecrets.s3Config = _s3Config
    charts.securecodebox.values = _values | securecodebox.Values {}
}
