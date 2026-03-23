import file

import konfig.models.frontend
import konfig.files

import kube_shared
import charts.nack

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "nack"
    tenantName = kube_shared.tenant.name

    charts.nack = nack.Chart {
        values: _values | nack.Values {}
    }
}
