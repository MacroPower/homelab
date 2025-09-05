import file

import {{.TenantName}}
import charts.{{.AppName}}
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "{{.AppName}}"
    tenantName = {{.TenantName}}.tenant.name

    charts.{{.AppName}} = {{.AppName}}.Chart {
        values: _values | {{.AppName}}.Values {}
    }
}
