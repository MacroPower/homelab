import file

import konfig.files
import konfig.objects

import kube_openebs_base
import charts.openebs

_baseValues = kube_openebs_base.app.charts.openebs.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = kube_openebs_base.app | {
    charts.openebs.values = _values | openebs.Values {}
}
