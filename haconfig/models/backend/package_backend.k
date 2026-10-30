import models.frontend
import models.mixins
import models.resource

schema PackageBackend[inputConfig: frontend.Package]:
    """
    PackageBackend converts the user-written front-end model `Package` into the
    domain-keyed contents of one `packages/<name>.yaml` file, and places them in
    the `hass` attribute. Each mixin writes one domain key.
    """
    mixin [
        mixins.CustomizeMixin,
        mixins.AutomationMixin,
        mixins.ScriptMixin,
        mixins.TemplateMixin,
        mixins.InputBooleanMixin,
        mixins.InputButtonMixin,
        mixins.InputNumberMixin,
        mixins.InputSelectMixin,
        mixins.InputTextMixin,
        mixins.InputDatetimeMixin,
        mixins.TimerMixin,
        mixins.CounterMixin,
        mixins.ScheduleMixin,
        mixins.ExtraConfigMixin,
    ]

    # Store the input config parameter, so the protocol and the mixins read it.
    config: frontend.Package = inputConfig

    hass: resource.DomainMapping = {}
