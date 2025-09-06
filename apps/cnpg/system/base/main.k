import file

import cnpg
import charts.cloudnative_pg
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "postgres"
    tenantName = cnpg.tenant.name

    charts.cloudnative_pg = cloudnative_pg.Chart {
        values: _values | cloudnative_pg.Values {}
    }
}
