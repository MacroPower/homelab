import file
import json

import {{.TenantName}}_{{.AppName}}_base
import charts.{{.TenantName}}_{{.AppName}}
import konfig.utils

_baseValues = {{.TenantName}}_{{.AppName}}_base.app.charts.{{.TenantName}}_{{.AppName}}.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = {{.TenantName}}_{{.AppName}}_base.app | {
    charts.{{.TenantName}}_{{.AppName}}.values = _values | {{.TenantName}}_{{.AppName}}.Values {}
}
