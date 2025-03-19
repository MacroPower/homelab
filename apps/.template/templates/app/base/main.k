import file

import {{.TenantName}}_tenant
import charts.{{.TenantName}}_{{.AppName}}
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app: frontend.App {
    name = "{{.AppName}}"
    tenantName = {{.TenantName}}_tenant.tenantConfiguration.name

    charts.{{.TenantName}}_{{.AppName}} = {{.TenantName}}_{{.AppName}}.Chart {
        values: _values | {{.TenantName}}_{{.AppName}}.Values {}
    }
}
