import file

import konfig.files
import konfig.objects

import cilium_tetragon_base
import charts.tetragon

_baseValues = cilium_tetragon_base.app.charts.tetragon.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = cilium_tetragon_base.app | {
    charts.tetragon.values = _values | tetragon.Values {}
}
