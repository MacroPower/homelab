import file

import argo_tenant
import charts.argo_cd
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app: frontend.App {
    name = "cd"
    tenantName = argo_tenant.tenantConfiguration.name

    charts.argo_cd = argo_cd.Chart {
        values: _values | argo_cd.Values {}
    }
}
