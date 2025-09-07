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
}
