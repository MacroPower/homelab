import file

import kube_postgres_base
import charts.cloudnative_pg
import konfig.utils

_baseValues = kube_postgres_base.app.charts.cloudnative_pg.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = kube_postgres_base.app | {
    charts.cloudnative_pg.values = _values | cloudnative_pg.Values {}
}
