import file

import konfig.models.frontend
import konfig.files

import o11y_shared
import charts.mimir

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "mimir"
    tenantName = o11y_shared.tenant.name

    secretStore = o11y_shared.shared.secretStores.default.name

    charts.mimir = mimir.Chart {
        values: _values | mimir.Values {}
    }
}
