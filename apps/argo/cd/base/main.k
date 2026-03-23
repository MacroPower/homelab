import file

import konfig.models.frontend
import konfig.files

import argo_shared
import charts.argo_cd

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "cd"
    tenantName = argo_shared.tenant.name
    secretStore = argo_shared.shared.secretStores.default.name

    charts.argo_cd = argo_cd.Chart {
        values: _values | argo_cd.Values {}
    }
}
