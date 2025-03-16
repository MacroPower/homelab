import file

import charts.external_secrets
import external_tenant
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app: frontend.App {
    name = "system"
    tenantName = external_tenant.tenantConfiguration.name

    charts.external_secrets = external_secrets.Chart {
        values: _values | external_secrets.Values {}
    }
}
