import file

import konfig.models.frontend
import konfig.files

import {{.TenantName}}
import charts.{{.AppName}}

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "{{.AppName}}"
    tenantName = {{.TenantName}}.tenant.name

    charts.{{.AppName}} = {{.AppName}}.Chart {
        values: _values | {{.AppName}}.Values {}
    }
}
