import file

import dragonfly_tenant
import charts.dragonfly_operator
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app: frontend.App {
    name = "operator"
    tenantName = dragonfly_tenant.tenantConfiguration.name

    charts.dragonfly_operator = dragonfly_operator.Chart {
        values: _values | dragonfly_operator.Values {}
    }
}
