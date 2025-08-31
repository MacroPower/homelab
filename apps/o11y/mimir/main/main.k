import file

import o11y_mimir_base
import charts.mimir
import konfig.utils

_baseValues = o11y_mimir_base.app.charts.mimir.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = o11y_mimir_base.app | {
    charts.mimir.values = _values | mimir.Values {}
}
