import file

import o11y
import charts.loki
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "loki"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    charts.loki = loki.Chart {
        values: _values | loki.Values {}
    }
}
