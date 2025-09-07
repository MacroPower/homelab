import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

import o11y_grafana_base
import charts.grafana_pdc_agent

_baseValues = o11y_grafana_base.app.charts.grafana_pdc_agent.values

app = o11y_grafana_base.app | {
    charts.grafana_pdc_agent.values = _baseValues | grafana_pdc_agent.Values {}

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
                                "app.kubernetes.io/component" = "nginx"
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
