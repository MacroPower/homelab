import file

import konfig.files
import konfig.objects

import o11y_osrs_ge_exporter_base
import charts.osrs_ge_exporter

_baseValues = o11y_osrs_ge_exporter_base.app.charts.osrs_ge_exporter.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Simple exporter with no Docker-unsafe items. The prometheus-operator CRDs
# (ServiceMonitor/PrometheusRule) are installed on the local cluster, so the
# base monitoring resources are kept verbatim. No GE data is reachable offline,
# so the exporter is Healthy but emits no scraped metrics.
app = o11y_osrs_ge_exporter_base.app | {
    charts.osrs_ge_exporter.values = _values | osrs_ge_exporter.Values {}
}
