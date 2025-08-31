import file

import kube_openebs_base
import charts.openebs
import konfig.utils

_baseValues = kube_openebs_base.app.charts.openebs.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = kube_openebs_base.app | {
    charts.openebs.values = _values | openebs.Values {}
}
