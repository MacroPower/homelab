import file

import konfig.files
import konfig.objects

import twitch_channel_points_miner_base
import cluster
import charts.tcpm

_baseValues = twitch_channel_points_miner_base.app.charts.tcpm.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Redirect every ExternalSecret remoteRef.key to "dummy" so the fake secret
# provider answers them offline. The miner runs but is inert: the twitch-cookie
# secret resolves to a dummy value with no real session, so no points are mined.
app = twitch_channel_points_miner_base.app | {
    domainName = cluster.DOMAIN_NAME
    externalSecrets.tcpmOIDCClient.data: {
        "client-id" = {remoteRef.key = "dummy"}
        "client-secret" = {remoteRef.key = "dummy"}
    }
    externalSecrets.twitchCookie.data: {
        "Cookie.pkl" = {remoteRef.key = "dummy"}
    }
    charts.tcpm.values = _values | tcpm.Values {}
}
