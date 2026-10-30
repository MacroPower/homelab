# The Home Assistant instance on the Pi. The defaults emit `default_config:`
# and the `!include` lines for the files that the HA UI owns.
#
# Add each package in its own file in this directory, such as `hallway.k`
# holding `hallway = frontend.Package {name = "hallway", ...}`, and add it to
# the list in `packages`. Define exactly one HomeAssistant in this module,
# because each variable that holds one adds an instance and fails the render.
# haconfig/examples/hallway holds a complete example, and docs/hass.md
# describes the rules.
#
# state.k holds the registry state, such as floors and areas, which
# `task hass:plan` and `task hass:apply` compare with the live instance.
import haconfig.models.frontend
import haconfig.tags

config = frontend.HomeAssistant {
    integrations = {
        # The Pi serves HA over HTTPS on 443 with the certificates in /ssl.
        http = {
            server_port = 443
            ssl_certificate = "/ssl/fullchain.pem"
            ssl_key = "/ssl/privkey.pem"
        }
        frontend.themes = tags.include_dir_merge_named("themes")
    }
    packages = {_p.name: _p for _p in []}
    state = hass_state
}
