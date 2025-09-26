import file

import konfig.models.frontend
import konfig.files

import crossplane_shared
import charts.crossplane

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "system"
    tenantName = crossplane_shared.tenant.name

    charts.crossplane = crossplane.Chart {
        values: _values | crossplane.Values {}
    }
}
