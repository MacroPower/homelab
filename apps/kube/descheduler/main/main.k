import file

import kube_descheduler_base
import charts.descheduler
import konfig.utils

_baseValues = kube_descheduler_base.app.charts.descheduler.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = kube_descheduler_base.app | {
    charts.descheduler.values = _values | descheduler.Values {}
}
