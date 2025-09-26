import file

import konfig.files
import konfig.objects

import crossplane_system_base
import charts.crossplane

_baseValues = crossplane_system_base.app.charts.crossplane.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = crossplane_system_base.app | {
    charts.crossplane.values = _values | crossplane.Values {}
}
