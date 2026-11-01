# The Home Assistant instance on the Pi. The defaults emit `default_config:`
# and the `!include` lines for the files that the HA UI owns.
#
# Add each package in its own file in this directory, such as `hallway.k`
# holding `hallway = frontend.Package {name = "hallway", ...}`, and add it to
# the list in `packages`. The files share one namespace, so start each
# private top-level name with a prefix for its package, such as `_sbs`.
# Define exactly one HomeAssistant in this module,
# because each variable that holds one adds an instance and fails the render.
# haconfig/examples/hallway holds a complete example, and docs/hass.md
# describes the rules.
#
# state.k holds the registry state, such as floors and areas, which
# `task hass:plan` and `task hass:apply` compare with the live instance.
import haconfig.models.frontend
import haconfig.tags

config = frontend.HomeAssistant {
    # The repo is public, so the home location comes from the Pi's
    # secrets.yaml, and `secrets` below holds fakes for the checks. Once this
    # block reaches the Pi, HA locks the General settings, the URLs, and the
    # home zone in the UI, so the block sets every one of them.
    core = {
        name = "Home"
        latitude = tags.secret("home_latitude")
        longitude = tags.secret("home_longitude")
        elevation = tags.secret("home_elevation")
        radius = 100
        unit_system = "us_customary"
        time_zone = "America/New_York"
        country = "US"
        currency = "USD"
        language = "en"
        internal_url = "https://hass.cin.macro.network"
        external_url = "https://hass.cin.macro.network"
    }
    secrets = {
        home_latitude = 40.7
        home_longitude = -74.0
        home_elevation = 10
    }
    integrations = {
        frontend.themes = tags.include_dir_merge_named("themes")
    }
    packages = {_p.name: _p for _p in [smart_bulb_switches]}
    state = hass_state
}
