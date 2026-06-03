import file

import konfig.files
import konfig.objects
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

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
