import file

import konfig.files
import konfig.objects

import kube_volsync_base
import charts.volsync

_baseValues = kube_volsync_base.app.charts.volsync.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# volsync is a single-replica operator with no Docker-unsafe items (no HW
# nodeSelectors, storage classes, LB VIPs, or quorum). The base
# CiliumNetworkPolicies resolve via the kube-apiserver/kube-dns entities on the
# local cluster, so the whole app is inherited verbatim aside from modest
# resource requests/limits suited to the single tald node.
app = kube_volsync_base.app | {
    charts.volsync.values = _values | volsync.Values {}
}
