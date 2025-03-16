import k8s.api.networking.v1 as networking_v1
import models.utils
import models.resource
import models.protocol

mixin IngressMixin for protocol.AppProtocol:
    if config.ingresses:
        kubernetes: resource.ResourceMapping {
            Ingress = [networking_v1.Ingress {
                metadata: utils.MetadataBuilder(_s)
                spec.rules = _s?.rules
                spec.tls = _s?.tls
            } for _i, _s in config.ingresses]
        }
