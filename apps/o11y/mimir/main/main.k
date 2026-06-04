import file

import konfig.files
import konfig.objects

import o11y_mimir_base
import charts.mimir
import cluster

_baseValues = o11y_mimir_base.app.charts.mimir.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_mimir_base.app | {
    charts.mimir.values = _values | mimir.Values {
        metaMonitoring.serviceMonitor.clusterLabel = cluster.NAME
    }
}
