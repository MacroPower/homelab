import file

import konfig.models.frontend
import konfig.files

import o11y
import charts.osrs_ge_exporter

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "osrs-ge-exporter"
    tenantName = o11y.tenant.name

    charts.osrs_ge_exporter = osrs_ge_exporter.Chart {
        values: _values | osrs_ge_exporter.Values {}
    }
}
