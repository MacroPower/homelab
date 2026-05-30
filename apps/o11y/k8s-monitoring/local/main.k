import file

import konfig.files

import o11y_k8s_monitoring_base
import charts.k8s_monitoring
import cluster

# Minimal k8s-monitoring for the Talos-in-Docker test cluster (see values.yaml).
# It replaces the base app's full Alloy values rather than merging over them, so
# the single node runs one collector instead of the whole logs/traces/Beyla
# pipeline, while still inheriting the prometheus_operator_crds chart from base
# -- which is the point: the curated local apps create ServiceMonitors and need
# the CRDs, delivered here by Argo CD exactly as the real clusters get them.
_values = files.read_yaml(file.current(), "values.yaml")

app = o11y_k8s_monitoring_base.app | {
    charts.k8s_monitoring.values = _values | k8s_monitoring.Values {
        cluster.name = cluster.NAME
    }

    extraResources = {}
}
