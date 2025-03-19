import file
import json

import {{.TenantName}}_{{.AppName}}_base
import charts.{{.TenantName}}_{{.AppName}}
import konfig.utils

_baseValues = {{.TenantName}}_{{.AppName}}_base.app.charts.{{.TenantName}}_{{.AppName}}.values
_values = utils.read_yaml(file.current(), "values.yaml")

app = {{.TenantName}}_{{.AppName}}_base.app | {
    charts.{{.TenantName}}_{{.AppName}}.values = _baseValues | _values | {{.TenantName}}_{{.AppName}}.Values {}
}
