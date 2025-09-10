import file

import konfig.files
import konfig.objects

import cluster
import starr_prowlarr_base
import charts.prowlarr

_baseValues = starr_prowlarr_base.app.charts.prowlarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = starr_prowlarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.prowlarr.values = _values | prowlarr.Values {}
}
