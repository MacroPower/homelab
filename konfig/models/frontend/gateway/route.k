import charts.envoy_gateway.api.v1 as gatewayv1
import models.frontend.common

schema Route(common.Metadata):
    hostnames?: [str] = []
    gatewayRef?: Gateway
    parentRefs?: [gatewayv1.GatewayNetworkingK8sIoV1HTTPRouteSpecParentRefsItems0]
    services?: {str:gatewayv1.GatewayNetworkingK8sIoV1HTTPRouteSpecRulesItems0BackendRefsItems0} = {}
    security?: SecurityPolicy
    homepage?: Homepage

schema Homepage:
    name?: str
    description?: str
    group?: str
    icon?: str
    weight?: int = 0
