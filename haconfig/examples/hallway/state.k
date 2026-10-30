# The registry state of the hallway example. `task hass:plan` compares it with
# the live instance. The areas collection is pruned, so the apply deletes every
# live area that this file lacks.
import haconfig.models.frontend.state as hstate

hallway_state = hstate.State {
    floors.ground = {name = "Ground Floor", level = 0, icon = "mdi:home-floor-0"}
    labels.motion = {name = "Motion", color = "amber", icon = "mdi:motion-sensor"}
    areas.hallway = {
        name = "Hallway"
        floor = "ground"
        icon = "mdi:door"
        aliases = ["Entry"]
        labels = ["motion"]
    }
    categories.automation.lighting = {name = "Lighting", icon = "mdi:lightbulb"}
    prune = ["areas"]
}
