# The overlay misspells a secret name. Every name that `tags.secret()`
# references must appear in `HomeAssistant.secrets`, so the render fails.
import haconfig.tags

import hallway

config = hallway.config | {
    core: {
        latitude = tags.secret("home_latitude")
        longitude = tags.secret("home_longtiude")
    }
}
