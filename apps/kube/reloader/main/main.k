import file

import konfig.files
import konfig.objects

import kube_reloader_base
import charts.reloader

_baseValues = kube_reloader_base.app.charts.reloader.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = kube_reloader_base.app | {
    charts.reloader.values = _values | reloader.Values {}
}
