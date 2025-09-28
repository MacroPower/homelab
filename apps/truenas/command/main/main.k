import file

import konfig.files
import konfig.objects

import truenas_command_base
import charts.truecommand

_baseValues = truenas_command_base.app.charts.truecommand.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = truenas_command_base.app | {
    charts.truecommand.values = _values | truecommand.Values {}
}
