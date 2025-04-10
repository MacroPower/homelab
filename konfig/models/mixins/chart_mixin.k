import models.resource
import models.protocol

import helm

mixin ChartMixin for protocol.AppProtocol:
    if config.charts:
        kubernetes: resource.ResourceMapping {
            Chart = [
                _obj
                for _, _chart in config.charts
                for _, _obj in helm.template(_chart | { namespace = config.namespace })
            ]
        }
