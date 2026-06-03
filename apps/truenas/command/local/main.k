import file

import konfig.files
import konfig.objects

import truenas_command_base
import charts.truecommand

_baseValues = truenas_command_base.app.charts.truecommand.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Local overlay: the only Docker-unsafe item is the data PVC's storageClass
# (openebs-mayastor doesn't exist on the single tald node); values.yaml
# repoints it to openebs-hostpath. The amd64 nodeSelector matches the tald
# node, so it stays. Repoint the route hostname to the local test domain so
# the gateway route is reachable.
app = truenas_command_base.app | {
    charts.truecommand.values = _values | truecommand.Values {}
    routes.truecommand.hostnames = ["truecommand.local.test"]
}
