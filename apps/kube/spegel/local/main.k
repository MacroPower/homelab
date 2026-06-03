import file

import konfig.files
import konfig.objects

import kube_spegel_base
import charts.spegel

_baseValues = kube_spegel_base.app.charts.spegel.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Inherit the real spegel DaemonSet (tolerations, hostPort, priorityClassName all
# stay). The base pins a hardware nodeSelector (topology.kubernetes.io/region: cin)
# that never matches the single tald node, so values.yaml drops that label via a
# json_merge_patch null so the DaemonSet schedules locally.
app = kube_spegel_base.app | {
    charts.spegel.values = _values | spegel.Values {}
}
