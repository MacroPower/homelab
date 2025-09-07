import file

import konfig.models.frontend
import konfig.files

import o11y
import charts.tempo

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "tempo"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    charts.tempo = tempo.Chart {
        values: _values | tempo.Values {}
    }
}
