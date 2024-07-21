import k8s.api.core.v1
import models.utils
import models.resource
import models.protocol

mixin ConfigMapMixin for protocol.AppProtocol:
    if config.configMaps:
        kubernetes: resource.ResourceMapping {
            ConfigMap = [v1.ConfigMap {
                metadata: utils.MetadataBuilder(_c)
                data = _c?.data
                binaryData = _c?.binaryData
            } for _i, _c in config.configMaps]
        }
