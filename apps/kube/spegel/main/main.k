import file

import konfig.files
import konfig.objects

import kube_spegel_base
import charts.spegel

_baseValues = kube_spegel_base.app.charts.spegel.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = kube_spegel_base.app | {
    charts.spegel.values = _values | spegel.Values {}
}
