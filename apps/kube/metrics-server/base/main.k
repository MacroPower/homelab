import file

import konfig.models.frontend
import konfig.models.templates.networkpolicy
import konfig.files

import kube
import charts.metrics_server

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "metrics-server"
    tenantName = kube.tenant.name

    charts.metrics_server = metrics_server.Chart {
        values = _values | metrics_server.Values {}
    }
}
