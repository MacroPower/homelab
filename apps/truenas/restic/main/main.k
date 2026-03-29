import file

import konfig.files
import konfig.objects

import truenas_restic_base
import cluster
import charts.restic

_baseValues = truenas_restic_base.app.charts.restic.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = truenas_restic_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.restic.values = _values | restic.Values {}
}
