import file

import konfig.models.frontend
import konfig.files

import o11y
import charts.k8s_monitoring

_values = files.read_yaml(file.current(), "values.yaml")

_kubernetesMixin = files.read_yaml(file.current(), "rules/kubernetes-mixin.yaml")

app = frontend.App {
    name = "k8s-monitoring"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    charts.k8s_monitoring = k8s_monitoring.Chart {
        values: _values | k8s_monitoring.Values {}
    }

    extraResources.kubernetesMixin = _kubernetesMixin
}
