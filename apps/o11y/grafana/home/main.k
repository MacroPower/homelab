import konfig.models.utils
import o11y_grafana_base

app = o11y_grafana_base.app | {
    environment = "home"
    domainName = "home.macro.network"

    grafanaDashboards = utils.DashboardPathBuilder("dashboards")

    extraResources.grafana.spec.config = o11y_grafana_base.GrafanaConfigBuilder(domainName)
}
