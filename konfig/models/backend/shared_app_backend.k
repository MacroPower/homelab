import models.frontend.shared_app
import models.mixins
import models.resource

schema SharedAppBackend[inputConfig: shared_app.SharedApp]:
    """
    AppBackend converts the user-written front-end model `App` into a collection
    of k8s resources and places the resource collection into the `k8s` attribute.
    """
    mixin [
        # Resource builder mixin
        mixins.ClusterRoleMixin,
        mixins.ClusterRoleBindingMixin,
        mixins.ClusterSecretStoreMixin,
    ]

    # Store the input config parameter, ensure it can be seen in protocol and mixin.
    config: shared_app.SharedApp = inputConfig

    _tmp = config

    kubernetes: resource.ResourceMapping = {}
