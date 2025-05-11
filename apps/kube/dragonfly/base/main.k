import file

import dragonfly
import charts.dragonfly_operator
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "dragonfly"
    tenantName = dragonfly.tenant.name

    charts.dragonfly_operator = dragonfly_operator.Chart {
        values: _values | dragonfly_operator.Values {}
    }
}
