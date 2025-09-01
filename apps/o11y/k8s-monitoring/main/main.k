import file

import o11y_k8s_monitoring_base
import charts.k8s_monitoring
import cluster
import konfig.models.frontend.secret
import konfig.utils

_baseValues = o11y_k8s_monitoring_base.app.charts.k8s_monitoring.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = o11y_k8s_monitoring_base.app | {
    charts.k8s_monitoring.values = _values | k8s_monitoring.Values {
        cluster.name = cluster.NAME
    }
}
