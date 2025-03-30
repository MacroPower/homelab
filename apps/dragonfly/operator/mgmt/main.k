import file
import json

import dragonfly_operator_base
import charts.dragonfly_operator
import konfig.utils

_baseValues = dragonfly_operator_base.app.charts.dragonfly_operator.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = dragonfly_operator_base.app | {
    charts.dragonfly_operator.values = _values | dragonfly_operator.Values {}
}
