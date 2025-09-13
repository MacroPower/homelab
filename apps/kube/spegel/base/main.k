import file

import konfig.models.frontend
import konfig.files

import kube
import charts.spegel

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "spegel"
    tenantName = kube.tenant.name

    charts.spegel = spegel.Chart {
        values: _values | spegel.Values {}
    }
}
