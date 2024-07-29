import models.utils
import models.resource
import models.protocol
import grafana_operator.v1beta1 as grafanav1beta1


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
