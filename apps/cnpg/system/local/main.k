import file

import konfig.files
import konfig.objects

import cnpg_system_base
import charts.cloudnative_pg

_baseValues = cnpg_system_base.app.charts.cloudnative_pg.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# CNPG owns no PVC and exposes only a ClusterIP webhook Service, so the base
# config runs unchanged on a single-node cluster; values.yaml pins replicaCount to 1.
app = cnpg_system_base.app | {
    charts.cloudnative_pg.values = _values | cloudnative_pg.Values {}
}
