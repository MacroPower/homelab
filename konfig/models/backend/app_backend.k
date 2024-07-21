import models.frontend.app
import models.mixins
import models.resource

schema AppBackend[inputConfig: app.App]:
    """
    AppBackend converts the user-written front-end model `App` into a collection
    of k8s resources and places the resource collection into the `k8s` attribute.
    """
    mixin [
        # Resource builder mixin
        mixins.ConfigMapMixin,
        mixins.SecretMixin,
        mixins.ServiceMixin,
        mixins.IngressMixin,
        mixins.ServiceAccountMixin,
        mixins.ChartMixin,
        mixins.NetworkPolicyMixin,
    ]

    # Store the input config parameter, ensure it can be seen in protocol and mixin.
    config: app.App = inputConfig

    _tmp = config

    kubernetes: resource.ResourceMapping = {}
