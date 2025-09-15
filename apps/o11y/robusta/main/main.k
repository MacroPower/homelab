import file

import konfig.files
import konfig.objects

import o11y_robusta_base
import cluster
import charts.robusta

_baseValues = o11y_robusta_base.app.charts.robusta.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_robusta_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.robusta.values = _values | robusta.Values {
        clusterName = cluster.NAME
    }
}
