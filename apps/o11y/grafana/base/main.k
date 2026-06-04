import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

import o11y_shared
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
    tenantName = o11y_shared.tenant.name

    secretStore = o11y_shared.shared.secretStores.default.name

    externalSecrets.pdcAgentCreds = _pdcAgentCreds

    charts.grafana_pdc_agent = grafana_pdc_agent.Chart {
        values: grafana_pdc_agent.Values {
            cluster = "prod-us-central-0"
            hostedGrafanaId = "165181"
            tokenSecretName = _pdcAgentCreds.name
        }
    }

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        o11yEgress = networkpolicy.NetworkPolicy {
            name = "o11y-egress"
            egress = [
                {
                    toEndpoints = [
                        {
                            matchLabels = {
                                "io.kubernetes.pod.namespace" = "o11y-loki"
                                "app.kubernetes.io/component" = "gateway"
                            }
                        }
                        {
                            matchLabels = {
                                "io.kubernetes.pod.namespace" = "o11y-tempo"
                                "app.kubernetes.io/component" = "gateway"
                            }
                        }
                        {
                            matchLabels = {
                                "io.kubernetes.pod.namespace" = "o11y-mimir"
                                "app.kubernetes.io/component" = "gateway"
                            }
                        }
                    ]
                }
            ]
        }
        grafanaCloudEgress = networkpolicy.NetworkPolicy {
            name = "grafana-cloud-egress"
            egress = [
                {
                    toFQDNs = [
                        {
                            matchPattern = "*.grafana.net"
                        }
                    ]
                }
            ]
        }
    }
}
