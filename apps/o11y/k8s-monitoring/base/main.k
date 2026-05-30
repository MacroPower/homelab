import file

import konfig.models.frontend
import konfig.files

import o11y_shared
import charts.k8s_monitoring
import charts.prometheus_operator_crds

_values = files.read_yaml(file.current(), "values.yaml")

_kubernetesMixin = files.read_yaml(file.current(), "rules/kubernetes-mixin.yaml")

app = frontend.App {
    name = "k8s-monitoring"
    tenantName = o11y_shared.tenant.name

    secretStore = o11y_shared.shared.secretStores.default.name

    charts.k8s_monitoring = k8s_monitoring.Chart {
        values: _values | k8s_monitoring.Values {}
    }

    # k8s-monitoring v4 no longer bundles the Prometheus Operator CRDs
    # (ServiceMonitor/PodMonitor/Probe/...), but its prometheusOperatorObjects
    # feature -- and ServiceMonitors across the fleet -- require them. Own them
    # here so Argo CD manages them instead of a one-off out-of-band install.
    # Version pin and the Prune=false/Delete=false cascade guard live in
    # charts/charts.k; instantiate with no value overrides to inherit them.
    charts.prometheus_operator_crds = prometheus_operator_crds.Chart {}

    extraResources.kubernetesMixin = _kubernetesMixin
}
