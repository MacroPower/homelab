import file

import konfig.files

import o11y_k8s_monitoring_base
import charts.k8s_monitoring
import cluster

# Minimal k8s-monitoring for the management cluster (see values.yaml). It
# replaces the base app's full Alloy values rather than merging over them, so
# mgmt runs one collector instead of the whole logs/traces/Beyla pipeline, while
# still inheriting the prometheus_operator_crds chart from base -- which is the
# point: mgmt runs ServiceMonitor-creating apps and needs the CRDs.
_values = files.read_yaml(file.current(), "values.yaml")

app = o11y_k8s_monitoring_base.app | {
    charts.k8s_monitoring.values = _values | k8s_monitoring.Values {
        cluster.name = cluster.NAME
    }

    extraResources = {}
}
