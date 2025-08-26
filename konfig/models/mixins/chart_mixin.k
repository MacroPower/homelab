import models.resource
import models.protocol

import helm

mixin ChartMixin for protocol.AppProtocol:
    if config.charts:
        _namespace: {str:str} = { namespace: config.namespace }
        kubernetes: resource.ResourceMapping {
            Chart = [
                _obj
                for _, _chart in config.charts
                for _, _obj in helm.template(_chartBuilder(config, _chart))
            ]
        }

_chartBuilder = lambda config: any, chart: helm.Chart -> helm.Chart {
    _chart = chart
    _namespace = config.namespace
    if _chart?.namespace == "":
        _chart.namespace = _namespace
    _chart
}
