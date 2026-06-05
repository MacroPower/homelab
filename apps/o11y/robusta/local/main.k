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
    # "dummy" key so the local fake secret store can answer them. The UI sink
    # that would consume the token is dropped in values.yaml ("dummy" is not a
    # valid base64 RobustaToken and crashes the runner at startup), so the
    # runner serves as a local event processor with no SaaS sink.
    externalSecrets.robustaConfig.data.ROBUSTA_SIGNING_KEY.remoteRef.key = "dummy"
    externalSecrets.robustaConfig.data.ROBUSTA_ACCOUNT_ID.remoteRef.key = "dummy"
    externalSecrets.robustaConfig.data.ROBUSTA_UI_SINK_TOKEN.remoteRef.key = "dummy"
}
