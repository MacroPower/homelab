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
# openebs-hostpath and drops the arch pin so the pod schedules on the single
# node regardless of its arch. Repoint the route hostname to the local test
# domain so the gateway route is reachable.
app = truenas_command_base.app | {
    charts.truecommand.values = _values | truecommand.Values {}
    routes.truecommand.hostnames = ["truecommand.local.test"]
}
