import file

import konfig.files
import konfig.objects

import starr_configarr_base
import charts.configarr

_baseValues = starr_configarr_base.app.charts.configarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = starr_configarr_base.app | {
    charts.configarr.values = _values | configarr.Values {}
}
