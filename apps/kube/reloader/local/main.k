import file

import konfig.files
import konfig.objects

import kube_reloader_base
import charts.reloader

_baseValues = kube_reloader_base.app.charts.reloader.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Inherit the real reloader app (including its CiliumNetworkPolicies, which use
# the kube-apiserver/kube-dns entities and resolve fine on the local cluster,
# and the PodMonitor, whose CRDs o11y/k8s-monitoring carries locally); only the
# single-node HA overrides in values.yaml (enableHA, replicas, PDB) are applied.
app = kube_reloader_base.app | {
    charts.reloader.values = _values | reloader.Values {}
}
