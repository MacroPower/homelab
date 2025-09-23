import file

import konfig.files
import konfig.objects

import public_opencloud_base
import cluster
import charts.opencloud

_baseValues = public_opencloud_base.app.charts.opencloud.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = public_opencloud_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.opencloud.values = _values | opencloud.Values {}
}
