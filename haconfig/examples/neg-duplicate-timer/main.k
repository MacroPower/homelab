# A second package reuses the object id `timer.hallway_light`. HA keeps only
# the first of two dict-merged keys, so the render fails instead.
import hallway

config = hallway.config | {
    packages.porch = {
        name = "porch"
        timers.hallway_light = {duration = "00:01:00"}
    }
}
