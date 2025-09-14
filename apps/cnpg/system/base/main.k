import file

import konfig.models.frontend
import konfig.files

import cnpg
import charts.cloudnative_pg

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "system"
    tenantName = cnpg.tenant.name

    charts.cloudnative_pg = cloudnative_pg.Chart {
        values: _values | cloudnative_pg.Values {}
    }
}
