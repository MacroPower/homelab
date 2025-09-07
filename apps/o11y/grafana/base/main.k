import konfig.models.frontend
import konfig.models.frontend.secret

import o11y
import charts.grafana_pdc_agent

_pdcAgentCreds = secret.ExternalSecret {
    name = "pdc-agent-credentials"
    data: {
        token = {
            remoteRef.key = "GRAFANA_PDC_AGENT_TOKEN"
        }
    }
}

app = frontend.App {
    name = "grafana"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    externalSecrets.pdcAgentCreds = _pdcAgentCreds

    charts.grafana_pdc_agent = grafana_pdc_agent.Chart {
        values: grafana_pdc_agent.Values {
            cluster = "prod-us-central-0"
            hostedGrafanaId = "165181"
            tokenSecretName = _pdcAgentCreds.name
        }
    }
}
