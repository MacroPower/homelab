# The overlay holds the root in an intermediate variable. Each variable adds a
# HomeAssistant instance to the main package, and the render requires exactly
# one, so it fails.
import hallway

_root = hallway.config | {
    packages.hallway.timers.hallway_light.duration = "00:03:00"
}

config = _root | {
    core.internal_url = "http://homeassistant.local:8123"
}
