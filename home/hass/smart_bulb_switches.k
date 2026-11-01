# The smart_bulb_switches package lets the Inovelli switches in Smart Bulb
# Mode control the Hue bulbs on their circuits. Smart Bulb Mode (parameter
# 52 = 1) keeps the bulbs powered. Each paddle press changes the switch's
# own state, which drives its LED bar, and sends a Central Scene event. These
# automations turn each event into a Hue command:
#
# - Tap up turns the bulbs on, and Hue restores their last brightness and
#   color. Tap down turns them off.
# - Two up taps set full brightness, and two down taps set a nightlight.
# - Holding a paddle brightens or dims the bulbs until you let go. Dimming
#   stops at 1% and leaves the bulbs on.
#
# Each switch's LED bar follows its group's reference light, whatever
# changed it, such as a paddle, the Hue app, or a Hue routine. The mirror
# switch's radar turns the mirror bulbs on and off.
#
# The package expects parameter 52 = 1 on every switch and parameter 110 = 0
# on the mmWave switches. Nothing in git sets either one. With parameter 110
# at 0, the radar does not change a switch's own state.
import haconfig.models.frontend
import haconfig.models.frontend.common
import haconfig.strings

# These names match the event_type values that the switches' scene event
# entities report.
_SBS_PRESSED = "KeyPressed"
_SBS_PRESSED_2X = "KeyPressed2x"
_SBS_HELD = "KeyHeldDown"
_SBS_RELEASED = "KeyReleased"

# Each hold step sets every light in the group to the next brightness, then
# waits up to _SBS_RAMP_INTERVAL seconds for the release. A sweep from 1% to
# 100% takes five steps, about 5 s. The Hue bridge tolerates about one group
# command a second, and a Hue room group gets one per step.
_SBS_RAMP_STEP = 20
_SBS_RAMP_INTERVAL = 1.0
# Two down taps set the bulbs to this brightness, in percent.
_SBS_NIGHTLIGHT_PCT = 5

schema SmartBulbGroup:
    """SmartBulbGroup is a set of Hue bulbs and the Smart Bulb Mode switches
    that control them. The group's key names its automations, such as
    `primary_bedroom_paddles`.

    Attributes
    ----------
    key: str, default is Undefined, required.
        Key is a slug, such as `primary_bedroom`.
    switches: [str], default is Undefined, required.
        Switches are the object ids of the switches, such as
        `primary_bedroom_mmwave_dimmer`. Each switch has the entities
        `light.<id>`, `event.<id>_scene_001` for the down paddle, and
        `event.<id>_scene_002` for the up paddle.
    lights: [str], default is Undefined, required.
        Lights are the Hue lights that the paddles drive. A Hue room group
        changes all of its bulbs with one command.
    reference: str, default is Undefined, required.
        Reference is the light whose state and brightness the LED bars and
        the hold ramp read.
    """
    key: str
    switches: [str]
    lights: [str]
    reference: str

    _notLights: [str] = [_sbL for _sbL in lights + [reference] if not _sbL.startswith("light.")]

    check:
        switches, "group `${key}` needs at least one switch"
        lights, "group `${key}` needs at least one light"
        not _notLights, "group `${key}` lights and reference must be light entities, got ${_notLights}"

_sbsGroups: [SmartBulbGroup] = [
    {
        # Each switch powers part of the room, and every one of them drives
        # the whole Hue room.
        key = "primary_bedroom"
        switches = ["primary_bedroom_mmwave_dimmer", "primary_bedroom_mmwave_dimmer_2", "primary_bedroom_2_1_dimmer"]
        lights = ["light.bedroom"]
        reference = "light.bedroom"
    }
    {
        key = "primary_bathroom_mirror"
        switches = ["primary_bathroom_mirror_mmwave_dimmer"]
        lights = ["light.hue_filament_bulb_1", "light.hue_filament_bulb_2", "light.hue_filament_bulb_3", "light.hue_filament_bulb_4"]
        reference = "light.hue_filament_bulb_1"
    }
    {
        key = "primary_bathroom_downlight"
        switches = ["primary_bathroom_2_1_dimmer_2"]
        lights = ["light.hue_color_downlight_8"]
        reference = "light.hue_color_downlight_8"
    }
]

_sbsMirror = [_sbG for _sbG in _sbsGroups if _sbG.key == "primary_bathroom_mirror"][0]
_sbsMirrorRadar = "binary_sensor.primary_bathroom_mirror_mmwave_dimmer_motion_detection"

# _sbsRamp steps the brightness of a group's lights in direction _sbDir (1
# or -1), starting from the reference's brightness. The ramp ends when a
# paddle in _sbPaddles reports its release, or when the brightness reaches
# 1% or 100%. The clamp also ends a hold whose release event never arrives.
# Restart mode ends the ramp on any other tap, double tap, or hold on the
# group's paddles.
_sbsRamp = lambda _sbG: SmartBulbGroup, _sbPaddles: [str], _sbDir: int -> [any] {
    _sbStep = _sbDir * _SBS_RAMP_STEP
    _sbLoop = {
        repeat = {
            sequence = [
                {
                    action = "light.turn_on"
                    target.entity_id = _sbG.lights
                    data = {
                        brightness_pct = "{{ [[start + ${_sbStep} * repeat.index, 1] | max, 100] | min }}"
                        transition = _SBS_RAMP_INTERVAL
                    }
                }
                {
                    wait_for_trigger = [
                        {trigger = "event.received", target.entity_id = _sbPaddles, options.event_type = [_SBS_RELEASED]}
                    ]
                    timeout = _SBS_RAMP_INTERVAL
                    continue_on_timeout = True
                }
            ]
            until = [
                strings.jinja("""\
                    {{ wait.trigger is not none
                       or state_attr(trigger.entity_id, 'event_type') != '${_SBS_HELD}'
                       or not 1 < start + ${_sbStep} * repeat.index < 100 }}
                """)
            ]
        }
    }
    [
        {condition = "template", value_template = "{{ states(ref) in ['on', 'off'] }}"}
        {
            variables.start = strings.jinja("""\
                {{ ((state_attr(ref, 'brightness') | int(255)) * 100 / 255) | round(0) | int
                   if is_state(ref, 'on') else 0 }}
            """)
        }
    ] + ([
        # Down holds leave bulbs that are off alone. Without this check, the
        # first step turns them on at 1%.
        {condition = "template", value_template = "{{ start > 0 }}"}
    ] if _sbDir < 0 else []) + [_sbLoop]
}

# HA derives each paddles automation's entity id from its default alias, the
# humanized map key, so the id is `automation.<key>_paddles`.
_sbsPaddles = lambda _sbG: SmartBulbGroup -> {str:any} {
    _sbUp = ["event.${_sbS}_scene_002" for _sbS in _sbG.switches]
    _sbDown = ["event.${_sbS}_scene_001" for _sbS in _sbG.switches]
    {
        description = "Drive the Hue lights from the paddles of their Smart Bulb Mode switches."
        mode = "restart"
        variables.ref = _sbG.reference
        triggers = [
            {trigger = "event.received", id = "up", target.entity_id = _sbUp, options.event_type = [_SBS_PRESSED]}
            {trigger = "event.received", id = "down", target.entity_id = _sbDown, options.event_type = [_SBS_PRESSED]}
            {trigger = "event.received", id = "up_2x", target.entity_id = _sbUp, options.event_type = [_SBS_PRESSED_2X]}
            {trigger = "event.received", id = "down_2x", target.entity_id = _sbDown, options.event_type = [_SBS_PRESSED_2X]}
            {trigger = "event.received", id = "up_held", target.entity_id = _sbUp, options.event_type = [_SBS_HELD]}
            {trigger = "event.received", id = "down_held", target.entity_id = _sbDown, options.event_type = [_SBS_HELD]}
        ]
        # Z-Wave JS can report a long hold again as another KeyHeldDown. The
        # automation checks its conditions before restart mode stops the
        # running ramp, so this condition keeps a repeat from restarting it.
        conditions = [
            strings.jinja("""\
                {{ not (trigger.id in ['up_held', 'down_held']
                        and trigger.from_state is not none
                        and trigger.from_state.attributes.event_type == '${_SBS_HELD}') }}
            """)
        ]
        actions = [
            {
                choose = [
                    {
                        conditions = [{condition = "trigger", id = "up"}]
                        sequence = [{action = "light.turn_on", target.entity_id = _sbG.lights}]
                    }
                    {
                        conditions = [{condition = "trigger", id = "down"}]
                        sequence = [{action = "light.turn_off", target.entity_id = _sbG.lights}]
                    }
                    {
                        conditions = [{condition = "trigger", id = "up_2x"}]
                        sequence = [{action = "light.turn_on", target.entity_id = _sbG.lights, data.brightness_pct = 100}]
                    }
                    {
                        conditions = [{condition = "trigger", id = "down_2x"}]
                        sequence = [{action = "light.turn_on", target.entity_id = _sbG.lights, data.brightness_pct = _SBS_NIGHTLIGHT_PCT}]
                    }
                    {
                        conditions = [{condition = "trigger", id = "up_held"}]
                        sequence = _sbsRamp(_sbG, _sbUp, 1)
                    }
                    {
                        conditions = [{condition = "trigger", id = "down_held"}]
                        sequence = _sbsRamp(_sbG, _sbDown, -1)
                    }
                ]
            }
        ]
    }
}

# _sbsLedBars sets each switch's own light, which in Smart Bulb Mode drives
# only its LED bar, to the reference's state and brightness. It runs when the
# reference or a switch changes. Each run writes only the switches that
# differ from the reference, so the report of its own write starts a run
# that writes nothing. No automation here drives the bulbs from a switch's
# own light, so the LED bar writes never move the bulbs.
#
# Each run waits a second, so a burst of changes ends in one write. It skips
# the write while the group's paddles automation runs, and while the
# reference is unavailable.
_sbsLedBars = lambda _sbG: SmartBulbGroup -> {str:any} {
    _sbSwitches = ["light.${_sbS}" for _sbS in _sbG.switches]
    {
        alias = "${common.humanize(_sbG.key)} LED bars"
        description = "Set the LED bars of the Smart Bulb Mode switches to the state and brightness of their Hue lights."
        mode = "restart"
        variables = {
            ref = _sbG.reference
            switches = _sbSwitches
            paddles = "automation.${_sbG.key}_paddles"
        }
        triggers = [
            {trigger = "state", entity_id = [_sbG.reference] + _sbSwitches}
            {trigger = "homeassistant", event = "start"}
            {trigger = "event", event_type = "automation_reloaded"}
        ]
        actions = [
            {delay = 1}
            {condition = "template", value_template = "{{ states(ref) in ['on', 'off'] }}"}
            {
                condition = "template"
                value_template = "{{ states(paddles) in ['on', 'off'] and state_attr(paddles, 'current') | int(0) == 0 }}"
            }
            {
                variables.stale = strings.jinja("""\
                    {% set on = is_state(ref, 'on') %}
                    {% set level = ((state_attr(ref, 'brightness') | int(255)) * 99 / 255) | round(0) | int %}
                    {% set ns = namespace(stale=[]) %}
                    {% for s in switches if states(s) in ['on', 'off'] %}
                      {% set s_level = ((state_attr(s, 'brightness') | int(0)) * 99 / 255) | round(0) | int %}
                      {% if is_state(s, 'on') != on or (on and (s_level - level) | abs > 1) %}
                        {% set ns.stale = ns.stale + [s] %}
                      {% endif %}
                    {% endfor %}
                    {{ ns.stale }}
                """)
            }
            {condition = "template", value_template = "{{ stale | length > 0 }}"}
            {
                $if = ["{{ is_state(ref, 'on') }}"]
                then = [
                    {
                        action = "light.turn_on"
                        target.entity_id = "{{ stale }}"
                        data = {brightness = "{{ state_attr(ref, 'brightness') | int(255) }}", transition = 0}
                    }
                ]
                $else = [
                    {action = "light.turn_off", target.entity_id = "{{ stale }}", data.transition = 0}
                ]
            }
        ]
    }
}

smart_bulb_switches = frontend.Package {
    name = "smart_bulb_switches"
    automations = {
        **{"${_sbG.key}_paddles": _sbsPaddles(_sbG) for _sbG in _sbsGroups}
        **{"${_sbG.key}_led_bars": _sbsLedBars(_sbG) for _sbG in _sbsGroups}
        # The radar's motion.cleared skips a change from unavailable, so a
        # state trigger also counts a radar that comes back off as cleared.
        primary_bathroom_mirror_presence = {
            description = "Turn the mirror bulbs on when the mirror switch's radar detects someone, and off when it clears."
            mode = "restart"
            triggers = [
                {trigger = "motion.detected", id = "detected", target.entity_id = _sbsMirrorRadar}
                {trigger = "motion.cleared", id = "cleared", target.entity_id = _sbsMirrorRadar}
                {trigger = "state", id = "cleared", entity_id = _sbsMirrorRadar, from = "unavailable", to = "off"}
            ]
            actions = [
                {
                    choose = [
                        {
                            conditions = [{condition = "trigger", id = "detected"}]
                            sequence = [{action = "light.turn_on", target.entity_id = _sbsMirror.lights}]
                        }
                        {
                            conditions = [{condition = "trigger", id = "cleared"}]
                            sequence = [{action = "light.turn_off", target.entity_id = _sbsMirror.lights}]
                        }
                    ]
                }
            ]
        }
    }
}
