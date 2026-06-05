import file

import konfig.files
import konfig.objects

import kube_metrics_server_base
import charts.metrics_server

_baseValues = kube_metrics_server_base.app.charts.metrics_server.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# The base's --kubelet-insecure-tls arg is inherited and still required here:
# the local Talos node does not enable kubelet serving-cert rotation, so there
# is no CSR-issued serving cert to verify (and the deployment carries no
# --kubelet-certificate-authority either). values.yaml drops the replica count
# to 1 to avoid a redundant pod on a single node.
app = kube_metrics_server_base.app | {
    charts.metrics_server.values = _values | metrics_server.Values {}
}
