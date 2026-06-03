import file

import konfig.files
import konfig.objects

import starr_configarr_base
import charts.configarr

_baseValues = starr_configarr_base.app.charts.configarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Inherit the real configarr app. The chart values are Docker-safe as-is
# (CronJob, openebs-hostpath PVC, emptyDir tmp, single execution -- nothing to
# spread or specialize for hardware). Only the ExternalSecret remote keys are
# redirected: the offline fake ClusterSecretStore serves a single "dummy" key,
# so each remoteRef.key must point at it for the secret to resolve. The CronJob
# still runs degraded -- the API keys are placeholder "dummy" values and the
# Sonarr/Radarr backends it syncs against are not deployed locally.
app = starr_configarr_base.app | {
    charts.configarr.values = _values | configarr.Values {}
    externalSecrets.configarr.data.SONARR_AUTH_APIKEY.remoteRef.key = "dummy"
    externalSecrets.configarr.data.RADARR_AUTH_APIKEY.remoteRef.key = "dummy"
}
