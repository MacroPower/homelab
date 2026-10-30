# The instance-wide config of the hallway example. It declares a fake value for
# every secret that the config references, lists the packages, and sets the
# registry state from state.k.
import haconfig.models.frontend
import haconfig.tags

config = frontend.HomeAssistant {
    core = {
        name = "Home"
        latitude = tags.secret("home_latitude")
        longitude = tags.secret("home_longitude")
        unit_system = "metric"
        time_zone = "America/New_York"
        country = "US"
        internal_url = "http://hass.cin.macro.network:8123"
    }
    integrations = {
        logger = {default = "warning"}
    }
    secrets = {
        home_latitude = 40.7
        home_longitude = -74.0
    }
    packages = {_p.name: _p for _p in [hallway]}
    state = hallway_state
}
