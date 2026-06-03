import file

import konfig.files
import konfig.objects

import o11y_wakatime_exporter_base
import charts.wakatime_exporter

_baseValues = o11y_wakatime_exporter_base.app.charts.wakatime_exporter.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Inherit the real app. The readme-updater CronJob stays suspended (base) and its
# openebs-hostpath PVC is fine on the local node; the serviceMonitor CRD is present
# locally so monitoring stays enabled. Only the Doppler-backed ExternalSecrets are
# redirected to the fake provider's "dummy" key so they resolve offline (the
# exporter and updater then run with placeholder credentials).
app = o11y_wakatime_exporter_base.app | {
    charts.wakatime_exporter.values = _values | wakatime_exporter.Values {}

    externalSecrets.wakatimeCreds.data.WAKATIME_API_KEY.remoteRef.key = "dummy"
    externalSecrets.readmeRepo.data.WAKATIME_GITHUB_REPO_URL.remoteRef.key = "dummy"
}
