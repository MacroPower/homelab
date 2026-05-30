import file

import konfig.files
import konfig.objects

import kube_descheduler_base
import charts.descheduler

_baseValues = kube_descheduler_base.app.charts.descheduler.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe descheduler: the base CronJob runs as-is (its CiliumNetworkPolicies
# resolve on the local cluster). Single-node eviction is inert but benign --
# nodeFit has nowhere to move a pod.
app = kube_descheduler_base.app | {
    charts.descheduler.values = _values | descheduler.Values {}
}
