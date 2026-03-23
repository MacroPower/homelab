import file

import kube_shared
import charts.dragonfly_operator
import konfig.models.frontend
import konfig.files

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "dragonfly"
    tenantName = kube_shared.tenant.name

    charts.dragonfly_operator = dragonfly_operator.Chart {
        values: _values | dragonfly_operator.Values {}
    }
}
