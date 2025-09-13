import file

import konfig.files
import konfig.objects

import cnpg_system_base
import charts.cloudnative_pg

_baseValues = cnpg_system_base.app.charts.cloudnative_pg.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = cnpg_system_base.app | {
    charts.cloudnative_pg.values = _values | cloudnative_pg.Values {}
}
