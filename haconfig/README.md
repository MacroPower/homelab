# Haconfig

Home Assistant configuration in [KCL](https://www.kcl-lang.io/).

Haconfig renders the YAML configuration of a Home Assistant (HA) instance from typed KCL models. It targets the HA release that `HASS_IMAGE` pins in `.taskfiles/hass/Taskfile.yaml`. It follows the layout of [konfig](../konfig/README.md). Users write front-end models. Mixins and backends turn them into HA's domain keys, and a render entry prints the result. It covers `configuration.yaml`, packages, automations, scripts, template entities, and the YAML helpers. The [Home Assistant guide](../docs/hass.md) covers the user config under `home/hass/` and the `task hass:*` commands.

## Directory Structure

The library has the following layout:

```bash
.
├── kcl.mod             # haconfig package metadata file
├── kcl.mod.lock        # haconfig package metadata lock file
├── examples            # The hallway worked example, its golden output, and negative render cases
├── strings             # dedent (vendored from konfig) and jinja
├── tags                # !secret, !include, and !env_var references
└── models
    ├── backend         # Back-end models
    ├── frontend        # Front-end models
    │   ├── common          # Shared types, slug and entity id checks, Target
    │   ├── core            # The `homeassistant:` block
    │   ├── trigger         # Triggers, their dispatcher, and the generated catalog
    │   ├── condition       # Conditions, their dispatcher, and the generated catalog
    │   ├── action          # Actions and their dispatcher
    │   ├── automation      # The `Automation` model
    │   ├── script          # The `Script` model
    │   ├── template        # Template sections and entities
    │   ├── helper          # input_*, timer, counter, and schedule helpers
    │   ├── home_assistant.k    # The `HomeAssistant` root model
    │   └── package.k           # The `Package` model
    ├── metadata        # Render context
    ├── mixins          # Mixins, one per HA domain
    ├── protocol        # Constraints for mixins
    ├── render          # Front-to-back-end renderer
    └── resource        # Domain mapping
```

## Usage

Config modules depend on haconfig by path, and each module adds the render entry to its profile. The `*.k` entry compiles every file in the module, so each package can sit in its own file:

```toml
[profile]
entries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]
```

The render prints one YAML stream of `{path, content}` documents: `configuration.yaml`, one `packages/<name>.yaml` per package, `secrets.example.yaml`, and `.gitignore`. It never writes to disk and never emits `secrets.yaml`, `automations.yaml`, `scripts.yaml`, or `scenes.yaml`.

The following example defines one package with a timer and an automation:

```python
import haconfig.models.frontend

hallway = frontend.Package {
    name = "hallway"
    timers.hallway_light = {duration = "00:05:00"}
    automations.motion_light = {
        triggers = [{trigger = "motion.detected", target.entity_id = "binary_sensor.hallway_motion"}]
        actions = [{action = "timer.start", target.entity_id = "timer.hallway_light"}]
    }
}

config = frontend.HomeAssistant {
    packages = {_p.name: _p for _p in [hallway]}
}
```

## Rules

Configs must follow these rules, because each one changes what HA loads:

- Every map key must be an HA slug (`[a-z0-9_]`, with no leading, trailing, or double `_`). Each key becomes an object id unchanged, and a check rejects other keys.
- Keys are part of the config's interface. The automation id and the template `unique_id` derive from `<package>.<key>`, so renaming a key orphans the old registry entry and its traces. Set `id` or `unique_id` to keep the old value.
- Every union (`|`) must write `=` to replace a list and `+=` to append to one. With `:`, KCL merges two lists by index into one hybrid entry.
- Every module must hold exactly one `HomeAssistant`. Every variable that holds one adds an instance, even a `_`-prefixed variable, and the render fails on a second instance.
- `HomeAssistant.secrets` must declare every name that `tags.secret()` references, with a fake value of the type HA validates. The render fails on an undeclared name.
- Pass multi-line Jinja templates through `strings.jinja`, so they render as `|-` blocks.
- Write every trigger, condition, action, and `sequence` field as a list, even with one entry. HA also accepts a single mapping or template string there, but haconfig rejects it, so `$if = "{{ ... }}"` becomes `$if = ["{{ ... }}"]`.

Trigger, condition, and action lists accept dict literals. Each family's dispatcher builds every entry into the schema that its HA discriminator names, and `Package` reports every invalid entry with its key path, such as `automations.motion_light.triggers[0]`.

## Escape Hatches

Each escape hatch is opt-in by name, so a typo never lands in one:

| Need | Escape hatch |
| --- | --- |
| A trigger, condition, or action that haconfig does not model | `trigger.RawTrigger {...}`, `condition.RawCondition {...}`, `action.RawAction {...}` |
| A template domain without a typed map | `TemplateSection.entities.<domain>.<key>` |
| An integration inside a package | `Package.extraConfig` |
| A hand-written automation or script inside a package | A labelled key, such as `extraConfig = {"automation raw" = [...]}` |
| A top-level integration | `HomeAssistant.integrations` |

## Tests

Tests sit next to the code in `*_test.k` files. Run them from this directory:

```bash
kcl test ./...
```

`task hass:gen` generates the trigger and condition catalogs in `models/frontend/{trigger,condition}/catalog.k` from the pinned HA release.

## License

Apache License Version 2.0
