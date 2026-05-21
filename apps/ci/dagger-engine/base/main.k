import file

import konfig.models.frontend
import konfig.files

import ci_shared
import charts.dagger_helm as dagger

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "dagger-engine"
    tenantName = ci_shared.tenant.name

    charts.dagger_helm = dagger.Chart {
        values = _values | dagger.Values {}
    }
}
