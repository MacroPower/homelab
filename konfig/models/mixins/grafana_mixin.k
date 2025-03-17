import charts.grafana_operator.api.v1beta1 as grafanav1beta1
import models.protocol
import models.resource
import models.utils


mixin GrafanaDashboardMixin for protocol.AppProtocol:
    if config.grafanaDashboards:
        kubernetes: resource.ResourceMapping {
            GrafanaDashboard = [grafanav1beta1.GrafanaDashboard {
                metadata: utils.MetadataBuilder(_c) | {
                    name: _i
                }
                spec: {
                    instanceSelector: {
                        matchLabels: {
                            dashboards = "grafana"
                        }
                    }
                    resyncPeriod: _c?.resyncPeriod
                    allowCrossNamespaceImport: _c?.allowCrossNamespaceImport
                    url: _c?.url
                    json: _c?.json
                }
            } for _i, _c in config.grafanaDashboards]
        }
