import charts.envoy_gateway.api.v1 as gatewayv1
import charts.envoy_gateway.api.v1alpha1 as gatewayv1alpha1

import models.utils
import models.resource
import models.protocol
import models.frontend.gateway

mixin RouteMixin for protocol.AppProtocol:
    if config.routes:
        kubernetes: resource.ResourceMapping {
            Route = [gatewayv1.HTTPRoute {
                metadata: utils.MetadataBuilder(config | {name = config.fullName} | {
                    annotations = {
                        if not isnullish(_route?.homepage):
                            "gethomepage.dev/enabled": "true"
                            "gethomepage.dev/name": _route.homepage.name
                            "gethomepage.dev/description": _route.homepage.description
                            "gethomepage.dev/group": _route.homepage.group
                            "gethomepage.dev/icon": _route.homepage.icon
                            "gethomepage.dev/pod-selector": ""
                            "gethomepage.dev/weight": str(_route.homepage.weight)
                    }
                } | _route)
                spec: {
                    if _route?.hostnames:
                        hostnames = [
                            _domainNameBuilder(config | {host.name = _hostname})
                            for _, _hostname in _route.hostnames
                        ]
                    else:
                        hostnames = [_domainNameBuilder(config | {host.name = config.name})]
                    parentRefs = _parentRefBuilder(_route)
                    rules = [{
                        backendRefs = [{
                            group = ""
                            kind = "Service"
                            name = _service.name
                            port = _service.port
                        } for _, _service in _route.services]
                    }]
                }
            } for _, _route in config.routes]

            SecurityPolicy = [gatewayv1alpha1.SecurityPolicy {
                metadata: utils.MetadataBuilder(config | {name = config.fullName} | _route)
                spec: {
                    targetRefs = [{
                        group = "gateway.networking.k8s.io"
                        kind = "HTTPRoute"
                        name = metadata.name
                    }]
                    oidc = {
                        provider.issuer = _route.security.oidcIssuer
                        clientIDRef = {
                            name = _route.security.oidcClientRef
                            namespace = config.namespace
                        }
                        clientSecret = {
                            name = _route.security.oidcClientRef
                            namespace = config.namespace
                        }
                        redirectURL = _route.security?.redirectURL
                        logoutPath = _route.security?.logoutPath
                    }
                }
            } for _, _route in config.routes if _route?.security != null]
        }


_parentRefBuilder = lambda route: gateway.Route -> [gatewayv1.GatewayNetworkingK8sIoV1HTTPRouteSpecParentRefsItems0] {
    if route?.parentRefs:
        route.parentRefs

    [{
        group = route.gatewayRef?.group
        kind = route.gatewayRef?.kind
        name = route.gatewayRef?.name
        namespace = route.gatewayRef?.namespace
        sectionName = "https"
    }]
}
