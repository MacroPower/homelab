# The hallway package turns the light on for motion when the hallway is dark,
# and turns it off when a timer ends. It uses a template sensor, an
# input_boolean override, a timer, and a script.
import haconfig.models.frontend
import haconfig.strings

_motion = "binary_sensor.hallway_motion"
_light = "light.hallway"
_override = "input_boolean.hallway_light_override"
_timer = "timer.hallway_light"

hallway = frontend.Package {
    name = "hallway"

    inputBooleans.hallway_light_override = {
        name = "Hallway light override"
        icon = "mdi:lightbulb-on"
    }

    timers.hallway_light = {
        name = "Hallway light"
        duration = "00:05:00"
    }

    templates.lux.sensors.hallway_lux = {
        name = "Hallway illuminance"
        unit_of_measurement = "lx"
        device_class = "illuminance"
        state_class = "measurement"
        availability = "{{ has_value('sensor.hallway_sensor_illuminance') }}"
        state = strings.jinja("""\
            {% set a = states('sensor.hallway_sensor_illuminance') | float(0) %}
            {% set b = states('sensor.stairs_sensor_illuminance') | float(a) %}
            {{ [a, b] | min | round(0) }}
        """)
    }

    scripts.hallway_light_on = {
        alias = "Hallway light on"
        mode = "restart"
        fields.brightness_pct = {
            name = "Brightness"
            default = 60
            selector.number = {min = 1, max = 100, unit_of_measurement = "%"}
        }
        sequence = [
            {action = "light.turn_on", target.entity_id = _light, data.brightness_pct = "{{ brightness_pct | default(60) }}"}
            {action = "timer.start", target.entity_id = _timer}
        ]
    }

    automations.motion_light = {
        alias = "Hallway motion light"
        description = "Turn the hallway light on for motion when it is dark, and off when the timer ends."
        mode = "restart"
        triggers = [
            {trigger = "motion.detected", id = "motion", target.entity_id = _motion}
            {trigger = "timer.finished", id = "timer_done", target.entity_id = _timer}
        ]
        conditions = [
            {condition = "state", entity_id = _override, state = "off"}
        ]
        actions = [
            {
                choose = [
                    {
                        conditions = [
                            {condition = "trigger", id = "motion"}
                            {condition = "numeric_state", entity_id = "sensor.hallway_lux", below = 30}
                        ]
                        sequence = [{action = "script.hallway_light_on", data.brightness_pct = 40}]
                    }
                    {
                        conditions = [{condition = "trigger", id = "timer_done"}]
                        sequence = [{action = "light.turn_off", target.entity_id = _light}]
                    }
                ]
            }
        ]
    }
}
