import file

import konfig.files
import konfig.objects

import {{.TenantName}}_{{.AppName}}_base
import charts.{{.AppName}}

_baseValues = {{.TenantName}}_{{.AppName}}_base.app.charts.{{.AppName}}.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = {{.TenantName}}_{{.AppName}}_base.app | {
    charts.{{.AppName}}.values = _values | {{.AppName}}.Values {}
}
