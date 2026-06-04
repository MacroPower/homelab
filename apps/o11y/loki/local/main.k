import file

import konfig.files
import konfig.objects

import o11y_loki_base
import charts.loki

_baseValues = o11y_loki_base.app.charts.loki.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_loki_base.app | {
    # The real S3 backend (seaweedfs) is offline locally, so point every remoteRef
    # at the fake "dummy" key the local provider answers. Loki will start but object
    # storage reads/writes fail until a real S3 endpoint exists (degraded).
    externalSecrets.s3Config.data: {
        S3_ACCESS_KEY.remoteRef.key = "dummy"
        S3_SECRET_KEY.remoteRef.key = "dummy"
    }

    charts.loki.values = _values | loki.Values {}
}
