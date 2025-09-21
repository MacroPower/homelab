import file

import konfig.files
import konfig.objects

import o11y_wakatime_exporter_base
import charts.wakatime_exporter

_baseValues = o11y_wakatime_exporter_base.app.charts.wakatime_exporter.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_wakatime_exporter_base.app | {
    charts.wakatime_exporter.values = _values | wakatime_exporter.Values {}
}
