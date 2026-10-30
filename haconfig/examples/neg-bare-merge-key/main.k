# The overlay sets a script field's default to the string `<<`. yaml.encode
# leaves it unquoted, and HA's YAML loader reads a bare `<<` as the merge tag,
# so the render fails instead of emitting a file that HA cannot load.
import hallway

config = hallway.config | {
    packages.hallway.scripts.hallway_light_on.fields.brightness_pct.default = "<<"
}
