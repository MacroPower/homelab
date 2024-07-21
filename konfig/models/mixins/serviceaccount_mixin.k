import k8s.api.core.v1
import models.utils
import models.resource
import models.protocol

mixin ServiceAccountMixin for protocol.AppProtocol:
    if config.serviceAccounts:
        kubernetes: resource.ResourceMapping {
            ServiceAccount = [v1.ServiceAccount {
                metadata: utils.MetadataBuilder(_s) | {
                    name = _s.name
                }
                imagePullSecrets = _s.imagePullSecrets
                secrets = _s.secrets
            } for _i, _s in config.serviceAccounts]
        }
