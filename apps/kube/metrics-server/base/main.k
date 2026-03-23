import file

import konfig.models.frontend
import konfig.models.templates.networkpolicy
import konfig.files

import kube_shared
import charts.metrics_server

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "metrics-server"
    tenantName = kube_shared.tenant.name

    charts.metrics_server = metrics_server.Chart {
        values = _values | metrics_server.Values {}
    }
}
