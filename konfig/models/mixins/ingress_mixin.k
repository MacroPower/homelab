import k8s.api.networking.v1 as networking_v1
import models.utils
import models.resource
import models.protocol

mixin IngressMixin for protocol.AppProtocol:
    if config.ingresses:
        kubernetes: resource.ResourceMapping {
            Ingress = [networking_v1.Ingress {
                metadata: utils.MetadataBuilder(config | { name = config.fullName } | _ingress)
                spec.ingressClassName = _ingress?.className
                spec.rules = [
                    {
                        host = _domainNameBuilder(config | { host = _rule?.host })
                        http.paths = [
                            {
                                path = _path.path
                                pathType = _path.pathType
                                backend = _path.backend
                            }
                            for _, _path in _rule.httpPaths
                        ]
                    }
                    for _, _rule in _ingress.rules
                ]
                spec.tls = [
                    {
                        hosts = [_domainNameBuilder(config | { host = _rule?.host })]
                        secretName = _rule?.tlsSecretName
                    }
                    for _, _rule in _ingress.rules
                ]
            } for _, _ingress in config.ingresses]
        }

_domainNameBuilder = lambda config: any -> str {
    _name = config.fullName
    _domainName = config.domainName
    _host = "${_name}.${_domainName}"
    if config?.host?.name:
        _name = config.host.name
        _host = "${_name}.${_domainName}"
    if config?.host?.fullName:
        _host = "${config.host.fullName}"

    _host
}
