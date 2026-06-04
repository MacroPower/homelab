import file

import konfig.files
import konfig.objects

import o11y_loki_base
import charts.loki

_baseValues = o11y_loki_base.app.charts.loki.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_loki_base.app | {
    # Point every remoteRef at the fake "dummy" key the local provider answers.
    # The S3 endpoint (values.yaml) targets the local o11y/seaweedfs overlay,
    # whose single identity uses the same literal dummy/dummy credentials, so
    # object storage works for real whenever that heavy stack is enabled.
    externalSecrets.s3Config.data: {
        S3_ACCESS_KEY.remoteRef.key = "dummy"
        S3_SECRET_KEY.remoteRef.key = "dummy"
    }

    charts.loki.values = _values | loki.Values {}
}
