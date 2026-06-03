import file

import konfig.files
import konfig.objects

import crossplane_system_base
import charts.crossplane

_baseValues = crossplane_system_base.app.charts.crossplane.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Single tald node: collapse the HA crossplane and rbac-manager deployments to
# one replica each (values.yaml). The base resources/metrics settings flow
# through unchanged.
app = crossplane_system_base.app | {
    charts.crossplane.values = _values | crossplane.Values {}
}
