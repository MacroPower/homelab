import file

import konfig.files
import konfig.objects

import cluster
import cilium_system_base

_baseValues = cilium_system_base.app.charts.cilium.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe Cilium: relaxed values, and drop the hubble-ui Ingress the
# bare-metal overlays add (no ingress controller or routable LB exists here).
app = cilium_system_base.app | {
    domainName = cluster.DOMAIN_NAME

    charts.cilium.values = _values

    ingresses = {}
}
