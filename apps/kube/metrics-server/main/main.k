import file

import kube_metrics_server_base
import charts.metrics_server
import konfig.utils

_baseValues = kube_metrics_server_base.app.charts.metrics_server.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = kube_metrics_server_base.app | {
    charts.metrics_server.values = _values | metrics_server.Values {}
}
