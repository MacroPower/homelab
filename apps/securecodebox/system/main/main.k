import file

import konfig.files
import konfig.objects

import securecodebox_system_base
import charts.securecodebox

_baseValues = securecodebox_system_base.app.charts.securecodebox.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = securecodebox_system_base.app | {
    charts.securecodebox.values = _values | securecodebox.Values {}
}
