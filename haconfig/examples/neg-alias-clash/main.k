# A second package reuses the alias `Hallway motion light`. HA derives the
# automation's entity id from its alias and appends `_2` on a clash, so the
# render fails instead.
import hallway

config = hallway.config | {
    packages.porch = {
        name = "porch"
        automations.porch_motion_light = {
            alias = "Hallway motion light"
            triggers = [{trigger = "motion.detected", target.entity_id = "binary_sensor.porch_motion"}]
            actions = [{action = "light.turn_on", target.entity_id = "light.porch"}]
        }
    }
}
