import file

import o11y_seaweedfs_base
import charts.seaweedfs
import konfig.utils

_baseValues = o11y_seaweedfs_base.app.charts.seaweedfs.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = o11y_seaweedfs_base.app | {
    charts.seaweedfs.values = _values | seaweedfs.Values {}
}
