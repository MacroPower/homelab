import file

import konfig.files
import konfig.objects

import kube_dragonfly_base
import charts.dragonfly_operator

_baseValues = kube_dragonfly_base.app.charts.dragonfly_operator.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = kube_dragonfly_base.app | {
    charts.dragonfly_operator.values = _values | dragonfly_operator.Values {}
}
