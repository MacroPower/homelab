import file

import konfig.files
import konfig.objects

import o11y_seaweedfs_base
import charts.seaweedfs

_baseValues = o11y_seaweedfs_base.app.charts.seaweedfs.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_seaweedfs_base.app | {
    charts.seaweedfs.values = _values | seaweedfs.Values {}

    # Redirect every S3 credential the s3-config ExternalSecret pulls from Doppler
    # to the fake-store "dummy" key so the offline external-secrets provider can
    # answer them. The buckets still get created; S3 auth is degraded (dummy creds).
    externalSecrets.s3Config.data: {
        MIMIR_S3_ACCESS_KEY.remoteRef.key = "dummy"
        MIMIR_S3_SECRET_KEY.remoteRef.key = "dummy"
        LOKI_S3_ACCESS_KEY.remoteRef.key = "dummy"
        LOKI_S3_SECRET_KEY.remoteRef.key = "dummy"
        TEMPO_S3_ACCESS_KEY.remoteRef.key = "dummy"
        TEMPO_S3_SECRET_KEY.remoteRef.key = "dummy"
    }
}
