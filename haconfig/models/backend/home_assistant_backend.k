import models.frontend
import models.resource
import tags

schema HomeAssistantBackend[inputConfig: frontend.HomeAssistant]:
    """
    HomeAssistantBackend converts the root front-end model `HomeAssistant` into
    the contents of `configuration.yaml`, and places them in the `hass`
    attribute. Like konfig's TenantBackend, it builds its output inline rather
    than through mixins.
    """
    config: frontend.HomeAssistant = inputConfig

    _core: {str:} = {**(config.core or {})} | {
        packages = tags.include_dir_named(config.packagesDir)
    }

    hass: resource.DomainMapping = {
        homeassistant = _core
        if config.defaultConfig:
            default_config = None
        if config.uiIncludes:
            automation = tags.include("automations.yaml")
            script = tags.include("scripts.yaml")
            scene = tags.include("scenes.yaml")
        **config.integrations
    }
