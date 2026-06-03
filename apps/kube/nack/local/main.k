import file

import konfig.files
import konfig.objects

import kube_nack_base
import charts.nack

_baseValues = kube_nack_base.app.charts.nack.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# nack is the NATS controllers (operator). No Docker-unsafe items: no HA spread,
# no hardware nodeSelectors, no PVCs. Inherit the base app verbatim.
app = kube_nack_base.app | {
    charts.nack.values = _values | nack.Values {}
}
