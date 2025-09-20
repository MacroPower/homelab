import file

import konfig.files
import konfig.objects

import securecodebox_seaweedfs_base
import charts.seaweedfs

_baseValues = securecodebox_seaweedfs_base.app.charts.seaweedfs.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = securecodebox_seaweedfs_base.app | {
    charts.seaweedfs.values = _values | seaweedfs.Values {}
}
