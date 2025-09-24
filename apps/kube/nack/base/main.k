import file

import konfig.models.frontend
import konfig.files

import kube
import charts.nack

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "nack"
    tenantName = kube.tenant.name

    charts.nack = nack.Chart {
        values: _values | nack.Values {}
    }
}
