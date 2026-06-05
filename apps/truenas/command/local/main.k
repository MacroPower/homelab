import file

import konfig.files
import konfig.objects

import truenas_command_base
import charts.truecommand

_baseValues = truenas_command_base.app.charts.truecommand.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Local overlay: Docker-unsafe items are the data PVC's storageClass
# (openebs-mayastor doesn't exist on the single tald node) and the pod's
# kubernetes.io/arch: amd64 nodeSelector; values.yaml repoints the class to
# openebs-hostpath and drops the arch pin so the pod can schedule at all.
# The image itself is amd64-only, so on an arm64 tald node it still dies with
# an exec format error -- the app ships disabled in .app.yaml (it also targets
# a real NAS that is unreachable offline). Repoint the route hostname to the
# local test domain so the gateway route renders against the local gateway.
app = truenas_command_base.app | {
    charts.truecommand.values = _values | truecommand.Values {}
    routes.truecommand.hostnames = ["truecommand.local.test"]
}
