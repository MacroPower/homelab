import models.resource
import models.protocol

import helm

mixin ChartMixin for protocol.AppProtocol:
    if config.charts:
        kubernetes: resource.ResourceMapping {
            Chart = [
                _obj
                for _, _chart in config.charts
                for _, _obj in helm.template(_chartBuilder(config, _chart))
            ]
        }

_chartBuilder = lambda config: any, chart: helm.Chart -> helm.Chart {
    _chart = chart
    if isnullish(_chart?.namespace):
        _chart.namespace = config.namespace
    _chart
}
