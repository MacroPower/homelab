import file

import konfig.files
import konfig.objects

import cluster
import starr_radarr_base
import charts.radarr

_baseValues = starr_radarr_base.app.charts.radarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = starr_radarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.radarr.values = _values | radarr.Values {}
}
