import konfig.models.utils
import base

appConfiguration = base.appConfiguration | {
    environment = "home"
    domainName = "home.macro.network"

    #grafanaDashboards = utils.DashboardPathBuilder("dashboards")

    extraResources.grafana.spec.config = base.GrafanaConfigBuilder(domainName)
}
