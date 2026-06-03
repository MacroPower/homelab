import file

import konfig.files
import konfig.objects

import o11y_robusta_base
import cluster
import charts.robusta

_baseValues = o11y_robusta_base.app.charts.robusta.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_robusta_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.robusta.values = _values | robusta.Values {
        clusterName = cluster.NAME
    }

    # No Doppler offline: point every robusta-config key at the fake provider's
    # "dummy" key so the local fake secret store can answer them. The runner gets
    # placeholder signing key / account id / UI sink token (degraded: cannot
    # authenticate to the Robusta SaaS UI, but the runner starts).
    externalSecrets.robustaConfig.data.ROBUSTA_SIGNING_KEY.remoteRef.key = "dummy"
    externalSecrets.robustaConfig.data.ROBUSTA_ACCOUNT_ID.remoteRef.key = "dummy"
    externalSecrets.robustaConfig.data.ROBUSTA_UI_SINK_TOKEN.remoteRef.key = "dummy"
}
