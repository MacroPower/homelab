import file

import o11y
import charts.k8s_monitoring
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "k8s-monitoring"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    charts.k8s_monitoring = k8s_monitoring.Chart {
        values: _values | k8s_monitoring.Values {}
    }
}
