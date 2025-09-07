import file

import konfig.files
import konfig.objects

import o11y_k8s_monitoring_base
import charts.k8s_monitoring
import cluster

_baseValues = o11y_k8s_monitoring_base.app.charts.k8s_monitoring.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_k8s_monitoring_base.app | {
    charts.k8s_monitoring.values = _values | k8s_monitoring.Values {
        cluster.name = cluster.NAME
    }
}
