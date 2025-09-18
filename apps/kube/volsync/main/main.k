import file

import konfig.files
import konfig.objects

import kube_volsync_base
import charts.volsync

_baseValues = kube_volsync_base.app.charts.volsync.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = kube_volsync_base.app | {
    charts.volsync.values = _values | volsync.Values {}
}
