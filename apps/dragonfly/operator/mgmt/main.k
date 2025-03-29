import file
import json

import dragonfly_operator_base
import charts.dragonfly_operator
import konfig.utils

_baseValues = dragonfly_operator_base.app.charts.dragonfly_operator.values
_values = utils.read_yaml(file.current(), "values.yaml")

app = dragonfly_operator_base.app | {
    charts.dragonfly_operator.values = _baseValues | _values | dragonfly_operator.Values {}
}
