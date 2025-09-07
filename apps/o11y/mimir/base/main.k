import file

import konfig.models.frontend
import konfig.files

import o11y
import charts.mimir

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "mimir"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    charts.mimir = mimir.Chart {
        values: _values | mimir.Values {}
    }
}
