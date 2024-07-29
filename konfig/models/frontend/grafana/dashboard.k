import models.frontend.common

schema GrafanaDashboard(common.Metadata):
    """
    Grafana Dashboard
    """
    resyncPeriod?: str = "1h"
    allowCrossNamespaceImport?: bool = True
    url?: str
    json?: str
