import file

import konfig.files
import konfig.objects

import kube_metrics_server_base
import charts.metrics_server

_baseValues = kube_metrics_server_base.app.charts.metrics_server.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = kube_metrics_server_base.app | {
    charts.metrics_server.values = _values | metrics_server.Values {}
}
