import o11y_grafana_base
import charts.grafana_pdc_agent

_baseValues = o11y_grafana_base.app.charts.grafana_pdc_agent.values

app = o11y_grafana_base.app | {
    charts.grafana_pdc_agent.values = _baseValues | grafana_pdc_agent.Values {}
}
