import file

import konfig.files
import konfig.objects

import twitch_channel_points_miner_base
import cluster
import charts.tcpm

_baseValues = twitch_channel_points_miner_base.app.charts.tcpm.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = twitch_channel_points_miner_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.tcpm.values = _values | tcpm.Values {}
}
