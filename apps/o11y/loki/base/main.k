import file

import konfig.models.frontend
import konfig.files

import o11y_shared
import charts.loki

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "loki"
    tenantName = o11y_shared.tenant.name

    secretStore = o11y_shared.shared.secretStores.default.name

    charts.loki = loki.Chart {
        values: _values | loki.Values {}
    }
}
