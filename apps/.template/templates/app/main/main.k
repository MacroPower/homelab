import file

import {{.TenantName}}_{{.AppName}}_base
import charts.{{.AppName}}
import konfig.utils

_baseValues = {{.TenantName}}_{{.AppName}}_base.app.charts.{{.AppName}}.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = {{.TenantName}}_{{.AppName}}_base.app | {
    charts.{{.AppName}}.values = _values | {{.AppName}}.Values {}
}
