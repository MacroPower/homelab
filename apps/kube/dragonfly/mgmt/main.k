import file
import json

import kube_dragonfly_base
import charts.dragonfly_operator
import konfig.utils

_baseValues = kube_dragonfly_base.app.charts.dragonfly_operator.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = kube_dragonfly_base.app | {
    charts.dragonfly_operator.values = _values | dragonfly_operator.Values {}
}
