import file

import konfig.files
import konfig.objects

import o11y_loki_base
import charts.loki

_baseValues = o11y_loki_base.app.charts.loki.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_loki_base.app | {
    externalSecrets.s3Config.data: {
        S3_ACCESS_KEY.remoteRef.key = "LOKI_S3_ACCESS_KEY"
        S3_SECRET_KEY.remoteRef.key = "LOKI_S3_SECRET_KEY"
    }

    charts.loki.values = _values | loki.Values {}
}
