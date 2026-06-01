import file

import konfig.files
import konfig.objects

import securecodebox_seaweedfs_main
import charts.seaweedfs

_baseValues = securecodebox_seaweedfs_main.app.charts.seaweedfs.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = securecodebox_seaweedfs_main.app | {
    externalSecrets.s3Config.data.SECURECODEBOX_S3_ACCESS_KEY.remoteRef.key = "dummy"
    externalSecrets.s3Config.data.SECURECODEBOX_S3_SECRET_KEY.remoteRef.key = "dummy"
    charts.seaweedfs.values = _values | seaweedfs.Values {}
}
