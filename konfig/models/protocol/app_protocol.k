import models.frontend.app
import models.resource

protocol AppProtocol:
    """AppProtocol provides constraints on mixins required by the app backend."""
    config: app.App
    kubernetes: resource.ResourceMapping
