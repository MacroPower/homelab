import file

import konfig.files
import konfig.objects

import o11y_grafana_base
import charts.grafana_pdc_agent

_baseValues = o11y_grafana_base.app.charts.grafana_pdc_agent.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_grafana_base.app | {
    charts.grafana_pdc_agent.values = _values | grafana_pdc_agent.Values {}

    # No Doppler offline: point the PDC token ExternalSecret at the fake
    # provider's "dummy" key. The agent gets a placeholder token (degraded,
    # cannot authenticate to Grafana Cloud).
    externalSecrets.pdcAgentCreds.data.token.remoteRef.key = "dummy"
}
