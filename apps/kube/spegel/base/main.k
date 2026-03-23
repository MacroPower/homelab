import file

import konfig.models.frontend
import konfig.files

import kube_shared
import charts.spegel

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "spegel"
    tenantName = kube_shared.tenant.name

    charts.spegel = spegel.Chart {
        values: _values | spegel.Values {}
    }
}
