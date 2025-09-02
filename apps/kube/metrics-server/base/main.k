import file

import charts.metrics_server
import konfig.models.frontend
import konfig.models.templates.networkpolicy
import konfig.utils
import kube

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "metrics-server"
    tenantName = kube.tenant.name

    charts.metrics_server = metrics_server.Chart {
        values = _values | metrics_server.Values {}
    }
}
