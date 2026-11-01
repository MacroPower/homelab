# Home Assistant Config

The Home Assistant (HA) config for the Pi lives in KCL under `home/hass/`, and the `haconfig/` library renders it into a complete HA config directory. `task hass:render` writes that directory under the gitignored `.cache/`, and `task hass:gate` validates the library and `home/hass/` against the pinned HA release. `task hass:deploy` uploads the directory to the Pi over SSH, as [Delivery](#delivery) describes.

The registries that HA keeps in `.storage`, such as floors, areas, and devices, are not YAML, and neither are the Supervisor apps, HACS, or the HTTP config. `home/hass/state.k` declares them, and `task hass:apply` writes them through HA's API, as [Registry State](#registry-state) describes.

This page covers the user config, the rules it must follow, and the tasks. The [haconfig README](../haconfig/README.md) describes the library's models.

## Layout

The config spans the library and one module for the Pi:

| Path | Holds |
| --- | --- |
| `haconfig/` | The library: front-end models, mixins, backends, and the render entry |
| `haconfig/examples/hallway/` | A complete worked example and its golden output |
| `haconfig/examples/neg-*/` | The negative render cases |
| `haconfig/engine/` | `hastate`, the Python engine that plans and applies registry state |
| `home/hass/` | The Pi's config: `main.k` with the instance-wide config, `state.k` with the registry state, and one file per package |

`home/hass/` sits outside `apps/` because HA config never deploys through Argo CD, and `home/` leaves room for home automation config that is not HA. The `home/hass/kcl.mod` file depends on the library and adds the render entry to its profile:

```toml
[package]
name = "home_hass"
version = "0.1.0"

[dependencies]
haconfig = { path = "../../haconfig" }

[profile]
entries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]
```

The `*.k` entry compiles every file in `home/hass/` as one KCL package, so adding a package file does not change `kcl.mod`. A second HA instance is one more module under `home/`, such as `home/hass-dev/`, with the same `kcl.mod` fields and its own package name. Pass its path to the tasks as `MODULE`.

The hallway example under `haconfig/examples/hallway` shows every part of a working config: a template sensor, an `input_boolean`, a timer, a script, an automation, and secrets.

The render prints one YAML stream, and `task hass:render` splits it into this directory:

```
.cache/hass/home/hass/config/
├── configuration.yaml        # homeassistant:, default_config:, the UI !include lines, integrations
├── packages/
│   └── <name>.yaml           # one file per package
├── secrets.example.yaml      # every referenced !secret name with its fake value
└── .gitignore                # the files HA writes at runtime
```

The render never writes `secrets.yaml`, `automations.yaml`, `scripts.yaml`, or `scenes.yaml`. `configuration.yaml` includes the three UI files, so automations, scripts, and scenes made in the HA UI keep working next to the generated packages.

## Adding a Package

A package is one `packages/<name>.yaml` file that groups the automations, scripts, templates, and helpers of one area or feature. To add one to the Pi's config:

1. Create `home/hass/<name>.k` with one top-level `Package`. Name the variable after the package, and set `name` to the same slug:

   ```python
   import haconfig.models.frontend

   hallway = frontend.Package {
       name = "hallway"
       timers.hallway_light = {name = "Hallway light", duration = "00:05:00"}
       automations.hallway_motion_light = {
           triggers = [{trigger = "motion.detected", target.entity_id = "binary_sensor.hallway_motion"}]
           actions = [{action = "timer.start", target.entity_id = "timer.hallway_light"}]
       }
   }
   ```

2. Add the variable to the list in `home/hass/main.k`. The files in `home/hass/` share one KCL package, so `main.k` reads `hallway` without an import:

   ```python
   packages = {_p.name: _p for _p in [hallway]}
   ```

3. Run `task hass:render`, and read `.cache/hass/home/hass/config/packages/hallway.yaml`.
4. Run `task hass:check` to load the output with HA's loader and run `check_config`.

If the package references a secret, declare it as [Secrets](#secrets) describes.

The files in `home/hass/` share one namespace, so each `_`-prefixed top-level name is one variable across every file. Every later file can assign the same name again, and the render reports no error. Start each private top-level name with a prefix for its package, such as `_sbs` in `smart_bulb_switches.k`.

Each `Package` collection is a map keyed by object id, and each one emits one HA domain:

| Field | Emits |
| --- | --- |
| `automations` | the `automation:` list |
| `scripts` | the `script:` map |
| `templates` | the `template:` list. Each key names one section, and the render does not emit it |
| `inputBooleans`, `inputButtons`, `inputNumbers`, `inputSelects`, `inputTexts`, `inputDatetimes` | the matching `input_*` map |
| `timers`, `counters`, `schedules` | the `timer:`, `counter:`, and `schedule:` maps |
| `customize` | `homeassistant: customize:` |
| `extraConfig` | any other key, verbatim |

Leaf fields take HA's own names, such as `unit_of_measurement`. HA keys that are KCL keywords take a `$` prefix (`$for`, `$if`, `$else`, `$while`), and the render writes them without it. Trigger, condition, and action lists accept dict literals, and the render builds each entry into the schema that its HA discriminator names.

Pass every multi-line Jinja template through `strings.jinja` from `haconfig.strings`. It strips trailing spaces, so the template renders as a `|-` block.

Write every trigger, condition, action, and `sequence` field as a list, even when it holds one entry. HA also accepts a single mapping or template string in those fields, but haconfig rejects that form, so `conditions = "{{ ... }}"` becomes `conditions = ["{{ ... }}"]`.

HA's package merge skips an empty mapping below a domain key without a message. The render therefore emits a helper written as `{}`, such as `timers.hallway_light = {}`, as `hallway_light: null`. It also emits a parameterless script selector such as `selector.boolean = {}` as `boolean: null`. The render does not rewrite `extraConfig`, so HA still drops an empty mapping that sits below one of its top-level keys.

## Union Rules

KCL's union operator (`|`) changes a config, for example in a negative render case or in a second instance that reuses a package. The following rules keep the result predictable.

The render requires exactly one `HomeAssistant` instance in the module, because one config directory has one `configuration.yaml`. Each variable that holds one, even a `_`-prefixed variable, adds an instance, so rebind a changed root in one expression:

```python
config = hallway.config | {
    packages.hallway.timers.hallway_light.duration = "00:03:00"
}
```

A second variable fails the render with `expected exactly one frontend.HomeAssistant in the main package, found 2`.

Every union must write `=` to replace a list field and `+=` to append to one. With `:`, KCL merges two lists by index, so the entry `conditions: [{condition = "template", ...}]` merges into the first existing condition. If the two entries differ in type, the render fails with `automations.motion_light.conditions[0]: No attribute named 'entity_id' in the schema 'TemplateCondition'`. If they share a type, the merge produces a wrong entry and the render succeeds.

To change a mapping, write `:` (`core: {internal_url = "..."}`), or set one leaf by its key path. To remove an entry, set it to `Undefined` (`packages.hallway.timers.hallway_light = Undefined`). On a collection entry, `None` also removes the entry. On a leaf field such as a trigger's `to`, `None` emits a YAML `null`.

## Identity

Map keys are the single source of every HA identity. For key `motion_light` in package `hallway`, the render derives these ids:

| HA identity | Source | Example |
| --- | --- | --- |
| Package name and file stem | `Package.name`, equal to its key | `packages/hallway.yaml` |
| Automation `id` | `<package>.<key>`, unless you set `id` | `hallway.motion_light` |
| Automation alias, and so its entity id | `alias`, or the key in sentence case | `Motion light`, so `automation.motion_light` |
| Template `unique_id` | `<package>.<key>`, unless you set `unique_id` | `hallway.motion_light` |
| Template `default_entity_id` | `<domain>.<key>`, unless you set it | `sensor.motion_light` |
| Script and helper object ids | the key | `script.motion_light`, `timer.motion_light` |

Every map key must be an HA slug: lowercase letters, digits, and single underscores, with no leading or trailing underscore. The `Package` checks reject other keys and list each one, such as `got [hallLight]`. The render does not convert keys, so the key you write is the id that traces and the entity registry show.

Keys are part of the config's interface. Renaming a key changes the automation id and the template `unique_id`, so HA orphans the old registry entry and loses its traces. To keep the old id across a rename, set `id` or `unique_id` to the old value. The same field lets an automation adopt the id of one that the UI created.

Derived ids with a package prefix never collide, because a slug cannot contain `.`. Explicit ids can still collide, and object ids and aliases have no prefix, so the render fails on each of these duplicates across packages:

- two automations with the same `id`
- two automation aliases that slugify to the same entity id
- two template entities of one domain with the same `unique_id`
- two template entities with the same `default_entity_id`
- two scripts or helpers of one domain with the same key

Start each script and helper key with the package's area, such as `hallway_light`, so that keys from different packages rarely clash.

The render cannot see the objects that the HA UI stores in `.storage/`. It misses every UI script or helper that shares a key with a YAML one, and HA keeps whichever one it loads first.

## Secrets

`tags.secret("name")` from `haconfig.tags` emits `!secret name`. Every name that the config references must also appear in `HomeAssistant.secrets`, mapped to a fake value:

```python
config = frontend.HomeAssistant {
    secrets = {
        home_latitude = 40.7
        home_longitude = -74.0
    }
}
```

The render fails on a referenced name that `secrets` does not declare, such as `undeclared secrets referenced: [home_longtiude]`. Each fake must have the type that HA validates, because the checks load the config with the fakes in place. A non-numeric latitude, such as `fake`, fails `cv.latitude`, and URL secrets need a URL. The repo is public, so every value in `secrets` must be fake.

The render emits `secrets.example.yaml`, which maps each referenced name to its fake. The real `secrets.yaml` lives only on the Pi, and you maintain it by hand. One `secrets.yaml` at the config root serves every file under `packages/`, because HA's loader searches parent directories up to the config directory.

## Tags

The `haconfig.tags` builders return a placeholder string, and the render turns each placeholder into a YAML tag after it encodes the file:

| Builder | Emits |
| --- | --- |
| `tags.secret(name)` | `!secret name` |
| `tags.include(path)` | `!include path` |
| `tags.include_dir_named(path)` | `!include_dir_named path` |
| `tags.include_dir_merge_named(path)` | `!include_dir_merge_named path` |
| `tags.include_dir_list(path)` | `!include_dir_list path` |
| `tags.include_dir_merge_list(path)` | `!include_dir_merge_list path` |
| `tags.env_var(name, default)` | `!env_var name default`, or `!env_var name` without a default. `name` must be one word |

Each builder rejects an empty argument and an argument that contains `"`, `\`, or a NUL byte. A plain string that starts with `!secret` stays a quoted string, so only a builder call produces a tag. haconfig does not support `!input`, because blueprints are out of scope.

## Escape Hatches

Each escape hatch covers an HA feature that haconfig does not model. You must name each one explicitly, so a typo in a modelled entry fails instead of landing in one:

| Need | Escape hatch |
| --- | --- |
| A trigger, condition, or action that haconfig does not model, such as `tag`, `device`, or `calendar` | `trigger.RawTrigger {...}`, `condition.RawCondition {...}`, `action.RawAction {...}` |
| A purpose trigger or condition from a custom integration | `trigger.RawTrigger {...}`, `condition.RawCondition {...}` |
| A template domain without a typed map, such as `light` or `weather` | `TemplateSection.entities.<domain>.<key>` |
| An integration inside a package | `Package.extraConfig` |
| A hand-written automation or script inside a package | a labelled key, such as `extraConfig = {"automation raw" = [...]}` |
| A top-level integration, such as `http` or `recorder` | `HomeAssistant.integrations` |

`extraConfig` rejects a plain key for a domain that the package models, such as `automation`, because HA merges it into the generated list by index. Write a labelled key instead. `integrations` rejects `homeassistant`, `default_config`, the UI include keys, and every domain that packages model.

## Validation

Each check runs at a different stage, and later checks catch what earlier ones cannot see:

| Stage | Check | Catches |
| --- | --- | --- |
| Render | Schema checks and the dispatchers | unknown keys, missing required keys, bad values, unknown trigger and condition names, non-slug keys |
| Render | Identity and secret checks in `render.k` | duplicate ids, `=` and `<<` strings, undeclared secrets, more than one root |
| `hass:load` | `annotatedyaml`, HA's own YAML loader | broken `!include` and `!secret` references, malformed packages |
| `hass:check` | `check_config` from the pinned HA image | everything HA validates, such as integration options and purpose-trigger option values |

Render errors name the package and the key path of each invalid entry, and each render reports every invalid entry at once:

```
Check failed on the condition: package `hallway` has invalid entries:
  automations.motion_light.triggers[0]: No attribute named 'too' in the schema 'StateTrigger'
```

The render checks purpose triggers and conditions, such as `motion.detected`, against a catalog generated from the pinned HA release. Misspelled names fail with ``unknown trigger `motion.detectedd` (not in the Home Assistant 2026.10.4 catalog)``. Without that check, `check_config` reports the misspelling only as a log line and exits 0.

`hass:check` runs `check_config` in Docker with no network, against a staged copy of the output. The stage adds empty UI files and copies `secrets.example.yaml` to `secrets.yaml`. HA requires every `http` certificate path to name an existing file. The check therefore mounts a read-only `/ssl` that holds an empty file for each `/ssl/<file>` path the config references. The check fails on a non-zero exit, on any error or warning in the JSON report, and on any `ERROR:` or `CRITICAL:` log line. It prints `WARNING:` log lines without failing.

## Tasks

The `hass` tasks live in `.taskfiles/hass/Taskfile.yaml`:

| Task | Variables | Runs |
| --- | --- | --- |
| `hass:render` | `MODULE` (default `home/hass`), `OUT`, `ARGS` | renders the module into `OUT`, by default `.cache/hass/<MODULE>/config` |
| `hass:load` | `MODULE` | `hass:render`, then stages the output and loads it with `annotatedyaml` |
| `hass:check` | `MODULE`, `HASS_IMAGE` | `hass:load`, then `check_config` in Docker |
| `hass:diff` | `MODULE`, `HASS_SSH`, `HASS_CONFIG_DIR`, `LIVE`, `SEMANTIC` | `hass:render`, then a diff from the live config to the render. See [Live Diff](#live-diff) |
| `hass:deploy` | `MODULE`, `HASS_SSH`, `HASS_CONFIG_DIR`, `HASS_URL`, `YES`, `RESTART`, `DRY_RUN` | `hass:check`, the diff, a confirmation, the upload, HA's config check, and a reload. See [Delivery](#delivery) |
| `hass:plan` | `MODULE`, `HASS_URL` | `hass:render`, then a plan of the registry state against live HA. See [Registry State](#registry-state) |
| `hass:apply` | `MODULE`, `HASS_URL`, `YES`, `RESTART` | `hass:plan`, a confirmation, the apply, and a second plan |
| `hass:import` | `OUT` (default `home/hass/state.k`), `VARIABLE`, `HASS_URL`, `FORCE` | writes a KCL state file from the live instance |
| `hass:e2e` | `HASS_IMAGE` | the engine's end-to-end tests against a fresh HA container |
| `hass:test` | `UPDATE` | the haconfig unit tests, the hallway golden diff, the negative render cases, and the engine's unit tests. `UPDATE=1` rewrites `golden/` |
| `hass:gate` | none | `hass:test`, `check_config` on the hallway example, then `hass:check` for `home/hass/` |
| `hass:gen` | `HASS_REF` (default the `HASS_IMAGE` tag) | regenerates the trigger and condition catalogs from `home-assistant/core` |
| `hass:lock` | none | regenerates every `kcl.mod.lock` under `haconfig/` and `home/hass/`. `kcl:lock` also runs it |

Run `task hass:gate` before you push a change to `haconfig/` or `home/hass/`. The repo has no CI for KCL, so the gate is the only check. To set the revision header in the rendered files, pass `ARGS="-D revision=<sha>"` to `hass:render`.

`HASS_IMAGE` pins the HA image by exact tag, and Renovate opens a pull request for each HA release. Renovate cannot regenerate the catalogs, so `hass:check` prints a note when the catalog version differs from the image tag. Run `task hass:gen` on that pull request before you merge it.

The negative render cases sit under `haconfig/examples/neg-*/`. Each one is a module that imports the hallway example, changes it with a union, and holds an `expected-error.txt`. `hass:test` fails when the module renders or fails with other text. To add a case, copy one of the directories, change its package name and `main.k`, and write the expected message.

## Live Diff

`task hass:diff` shows what `task hass:deploy` changes on the Pi. It renders the module, reads the live copy of every file that the render writes and of the package directory, and prints a `git diff` from `live/` to `rendered/`:

- A rendered file that the Pi lacks shows as a new file.
- A file that only the Pi holds under `packages/` shows as deleted, even when the render holds no packages. HA loads every file in that directory, so the deploy removes the file.
- A referenced secret that no `secrets.yaml` on the Pi defines prints a warning after the diff, because HA fails to load the config.

The task never writes to the Pi, and it never copies a `secrets.yaml` file or a symlink. Over SSH, the Pi checks each declared secret name itself and returns only the missing names, so no secret value leaves the Pi.

The task reads the Pi over one SSH connection, with `tar`. It needs one of the HAOS SSH apps, set up as follows:

- **Terminal & SSH:** add your public key to the app's `authorized_keys` option. The app does not listen on the network by default, so set a host port, such as 22, in its Network settings, and restart it.
- **Advanced SSH & Web Terminal:** add your key, and set `ssh.username` to `root`. The app's default user is `hassio`, an unprivileged user, so `HASS_SSH=root@...` fails until you change it.

SSH runs in batch mode, so connect once by hand (`ssh root@hass.cin.macro.network`) to accept the host key. `HASS_SSH` sets the destination. For a port other than 22, write `HASS_SSH=ssh://root@hass.cin.macro.network:2222`, or add a host entry to `~/.ssh/config`. `HASS_CONFIG_DIR` sets the config directory, which defaults to `/config`. Both apps mount the config at `/homeassistant` and link `/config` to it.

`LIVE=<dir>` reads a local directory instead of SSH, such as a mount of the Pi's Samba `config` share. In that mode, the script parses each `secrets.yaml` through the mount and keeps only its keys. The values cross the network to your machine, but they never reach the output. `SEMANTIC=1` parses every YAML file on both sides and re-dumps it with sorted keys, no comments, and no anchors. The diff then shows only changes that HA sees. Use it for the first migration, when the hand-written files on the Pi differ from the render in comments and key order.

The task succeeds whether or not the trees differ, and fails when it cannot read the live config.

## Registry State

`HomeAssistant.state` declares the floors, areas, labels, and categories that HA keeps in `.storage`, the settings of its devices, entities, and integrations, the Supervisor apps, the HACS repositories, and the HTTP server config. The render writes the state to `.cache/hass/<MODULE>/state.json`, next to the config directory and never in it. `task hass:plan` compares that file with the live registries, and `task hass:apply` makes HA match it:

```
Home Assistant 2026.10.3 at https://hass.cin.macro.network

  + floors.upstairs  "Upstairs"
        name: "Upstairs"
        level: 2
  ~ areas.office  "Office"
        floor_id: "ground" => "upstairs"
  ? areas.table  "Table"  (not in the state; prune areas to delete it)

Plan: 1 to create, 1 to update, 0 to delete. 1 unmanaged.
```

The state tasks talk to `HASS_URL`, which defaults to `https://hass.cin.macro.network`, and read an admin long-lived access token from `HASS_TOKEN`. To create one, open your HA profile, choose the Security tab, and create a token under Long-lived access tokens. Keep it in Doppler and run the tasks through `doppler run -p <project> -c <config> -- task hass:plan`, or export it in your shell.

`task hass:import` writes `home/hass/state.k` from the live registries, so git starts from the live state. Run it again with `FORCE=1` to replace the file with the live state, for example after you changed many areas in the UI. A plan of a fresh import shows no changes.

### Ownership

Each map key is the object's HA id, such as `living_room` for an area. The state owns every field of each object it declares, so an unset field clears that field in HA. Removing `icon` from an area removes the area's icon. To rename an area, change its `name` and keep its key. A new key creates a new object, because HA derives an id from the name at creation and never changes it. The apply creates each object under a temporary name that HA turns into the key, such as `office ~`, checks that HA assigned the key as the id, and then sets the real name.

The engine manages each collection that the state sets, and never reads or writes a collection that the state leaves unset. A live object that a managed collection lacks shows as unmanaged (`?`), and the apply deletes it only when `prune` names the collection:

```python
hass_state = hstate.State {
    areas = {...}
    prune = ["areas"]
}
```

HA gives each category a random id, so the engine matches categories by name within their scope, such as `automation`. Renaming a category in git creates a new one, and the old one stays until `prune` names `categories`. A managed `categories` covers the `automation`, `script`, `scene`, and `helpers` scopes and every scope the state names, so a category made in the UI shows as unmanaged.

### Devices, Entities, and Integrations

HA creates devices, entities, and config entries itself, when you pair a device or add an integration. The state never creates or deletes one. It manages only the fields that each declared object sets, so an unset field keeps the value HA has, and `None` clears the field:

```python
hass_state = hstate.State {
    devices.reading_lamp = {
        match.id = "4bc3...e91"
        name = "Reading Lamp"
        area = "living_room"
    }
    entities = {
        "light.reading_lamp" = {icon = "mdi:lamp", aliases = ["Book light"]}
        "sensor.lamp_power" = {match = {platform = "hue", uniqueId = "00:17:88-0b-power"}, hidden = True}
    }
    integrations.hue = {domain = "hue", entryId = "01JK...", title = "Hue Bridge"}
}
```

- **Devices:** a device's map key is a slug of your choice, and `match` finds the device by its registry id, one identifier, or one connection. `task hass:import` writes the registry id, which HA assigns when it adds the device and never changes.
- **Entities:** an entity's map key is its entity id. With `match`, the plan finds the entity by its platform and unique id within the key's domain, and the apply renames it to the key. HA strips each alias. It also keeps a placeholder for the entity's own name among the aliases. Google Assistant and Alexa use the first entry as the primary name, so the apply leaves the placeholder where it was.
- **Integrations:** the plan warns about each declared integration that HA lacks (`!`), and lists each live one that the state lacks. You add integrations in the UI. `task hass:import` leaves out each title that holds an email address, and the entry id alone matches the entry.

`disabled` and `hidden` set and clear only the flags that you set. HA also records flags that an integration, a device, or a config entry sets, and the plan warns when the state asks to clear one of those. HA enables an entity only when its device is enabled, so the plan checks the device's state after the apply. That state includes the devices that HA enables or disables along with an integration, so the state can enable an integration, a device, and its entities together. HA reloads an integration 30 seconds after you enable one of its entities. `task hass:import` lists only the devices and entities that carry a setting you made, with only those settings.

### Apps

`apps` declares Supervisor apps by slug, such as `core_mosquitto`. The engine reaches the Supervisor through HA's WebSocket API with the same token, so it does not need SSH. The plan installs each declared app that HA lacks, and uninstalls a live one that the state lacks only when `prune` names `apps`. It manages only the fields each app sets, and `options` manages each top-level option it sets. A set option holds its whole value, so a map lists every key it needs:

```python
apps.core_mosquitto = {
    # renovate: datasource=custom.ha-app depName=core_mosquitto packageName=home-assistant/apps/master/mosquitto
    version = "7.1.3"
    options = {logins = [{username = "zigbee", password = tags.secret("mqtt_password")}]}
    started = True
}
```

- **Secrets:** `tags.secret(name)` passes `!secret name` to the Supervisor, which reads the value from the Pi's `secrets.yaml`, so the value never enters git. Declare the name in `HomeAssistant.secrets`. Only the Supervisor resolves `!secret`, so the render accepts `tags.secret()` only as the whole value of an app option. The plan never prints the value of an option that the app marks as a password or whose name looks like a credential or personal data, such as `network_key` or `email`. It also hides options that hold free-form settings, such as `env_vars`, options that move to a secret, and URLs that hold credentials. Error messages from the Supervisor leave out option values.
- **Import:** `task hass:import` writes only the options whose type cannot hold free text, such as booleans, numbers, and selects. It skips options without a value. It names every other option in a comment above the app, so you can add it by hand, with `tags.secret()` for a secret.
- **Types:** the Supervisor stores each option in its schema's type, such as a select value as a string, and the plan compares the stored form. The Supervisor reloads `secrets.yaml` and checks the options before it stores them, so a bad option fails its step and changes nothing.
- **Defaults:** the Supervisor reports a removed option with its default value, so the state rejects `None` as an option value. Set the default value instead.
- **Versions:** the Supervisor installs and updates only to the latest version in its store. A pinned `version` therefore works as a gate. The apply updates the app when the store offers exactly the pinned version, and the plan warns when the store offers another one. `task hass:import` pins the version of each app that does not update itself, and of no other app.
- **Checks:** the plan checks each installed app's options, ports, and boot rules. The store does not list them for an app that is not installed, so the apply checks a new app after it installs the app, and before it writes any option.
- **Restarts:** the apply restarts a running app after its options or ports change, because the app reads them only when it starts. An app step that restarts the proxy or tunnel that `HASS_URL` goes through drops the engine's connection, so the apply stops there, and you run it again. Leave `started` unset for an app that runs once at startup, such as Let's Encrypt, because it stops on its own.
- **Repositories:** `appRepositories` lists the URLs of third-party store repositories, such as `https://github.com/hacs/addons`. The built-in repositories are always present. One apply can add a repository and install an app from it. `task hass:import` leaves out each repository whose URL holds credentials, because the Supervisor keys a repository by its whole URL.

### HACS

`hacs` declares HACS repositories by GitHub name, each with its category and its release tag, or a full commit sha for a repository without releases. The plan adds a custom repository that HACS does not know, and removes a live one that the state lacks only when `prune` names `hacs`. It never removes HACS itself, and the apply updates HACS before the other repositories. HACS 2.0.5 can install the latest release of a plugin that it has not installed before, even when the state pins an older tag. It still records the pinned tag, so pin a plugin's newest release on its first install.

HA loads integration code only when it starts, so the plan ends with a note after it changes an integration. `task hass:apply RESTART=1` restarts HA and waits until HA, the Supervisor, and HACS run again. A new HACS version also runs only after a restart, so with `RESTART=1` the apply restarts HA between the HACS update and the other downloads. Without it, the other downloads run on the old HACS. `task hass:import` writes the commit that HACS reports for a repository without releases, which is often the 7-character short form, and a comment asks you to replace it with the full commit hash.

### HTTP

`http` declares HA's HTTP server config, which HA keeps in `.storage/http` and ignores in YAML after its first boot on 2026.8 or later. The render therefore rejects `http` in `HomeAssistant.integrations`. HA replaces the whole config on each change, so the state owns every field, and an unset field takes HA's default. Under the Supervisor, the default port is 80:

```python
http = {
    serverPort = 443
    sslCertificate = "/ssl/fullchain.pem"
    sslKey = "/ssl/privkey.pem"
}
```

An HTTP change runs after every other step:

1. The apply stages the new config, and HA restarts.
2. The apply reconnects. When `HASS_URL` reaches HA directly and the port or TLS changed, it reconnects at the new URL.
3. It checks that HA booted on the new config, then confirms the config.
4. It waits until HA, the Supervisor, and HACS run again, then plans again.

Behind a proxy, `HASS_URL` stays the same, and the plan warns that a port or TLS change needs a matching change to the proxy. The plan also warns when HA drops TLS, because the apply then sends the token in plain text. HA reverts to the previous config 5 minutes after the restart unless the apply confirms it, so a config that locks the engine out undoes itself. HA checks certificate files and bind addresses only when it boots, and the plan warns when a change touches them. Without `sslKey`, HA reads the key from the certificate file.

### Version Bumps

Renovate bumps each `version` that has a `# renovate:` comment on the line above it, through the regex manager in `.github/renovate.json5`. `task hass:import` writes the comments:

- **HACS repositories:** `datasource=github-releases depName=<owner>/<repo>`.
- **Apps from the official and community stores:** `datasource=custom.ha-app`, which reads the app's `config.yaml` in its store repository. That file holds the version the Supervisor offers, so a Renovate pull request proposes only a version the apply can install.

### Plan Problems

The plan fails on each problem that would make the apply fail or lose data:

- An area names a floor or a label that neither HA nor the state holds. HA drops an unknown label without an error.
- A pruned floor or label is on an area that the state does not declare. HA would clear it from that area, so declare the area or move it first.
- Two objects in one collection would share a name, ignoring case and, for floors, areas, and labels, spaces. HA rejects the second.
- An area's `temperatureEntity` or `humidityEntity` has no state in HA, or lacks the matching device class.
- A live object holds the temporary name that a create needs.
- A device match finds no device or more than one, or two devices match one device.
- An entity's key or `match` finds no entity, or a rename needs an entity id that another entity holds.
- An entity on a device sets an area of its own but has no name apart from the device's name. HA rejects that area, so set the entity's name, or the area on its device.
- An entity names a category that neither HA nor the state holds, or enables an entity whose device stays disabled.
- An integration sets `title`, `disableNewEntities`, or `disablePolling` to `None`, which HA rejects.
- An app is missing from the store and from every repository that the plan adds, or pins a version the store does not offer.
- An app sets an option or a port that it lacks, or a field that the Supervisor ignores for it.
- HACS is not installed or not running, or a repository's category differs from the one HACS lists.
- HA holds a pending HTTP config that nobody confirmed, or the new config requires a client certificate.

HA also removes a deleted label from every device and entity, and a deleted category from every automation or script in it. The plan lists those counts under each delete, such as `also removes the label from 3 entities and 0 devices`.

The apply runs the deletes first, so a create or a rename can take a name that a pruned object held. It then runs labels, floors, areas, categories, integrations, devices, entities, apps, and HACS, so each object exists before another references it. The app steps add repositories first, then uninstall apps, then remove repositories, and then install and configure the declared apps. The apps stop, restart, and then start last, in that order, so a host port that one app releases is free before another takes it. The HTTP change runs last.

When a rename needs the old name of another renamed object, the apply first moves that object to a temporary name, so swaps and chains of renames work. The apply stops at the first failed step, and every step before it stays applied, so a new plan shows what remains. After the last step, it plans again and fails when changes remain.

`task hass:apply` asks you to type `yes`. It then reads HA again and stops when the plan changed or gained a problem while it waited. `YES=1` skips the question, and any other value of `YES` asks.

### Engine

`haconfig/engine/` is a uv project, and the tasks run it with `uv run`. Its unit tests run in `task hass:test`, against a fake HA that follows the registry, Supervisor, and HACS rules. `task hass:e2e` starts the pinned HA image in Docker with the `demo` integration and onboards a user through the onboarding API. It then runs plan, apply, prune, an HTTP change with its restart, and an import round trip through KCL against it. The container has no Supervisor and no HACS, so apps and HACS run only against the fake and in a read-only plan of the Pi. It reaches the container through `docker exec`, because published ports reset connections on some rootless Docker setups. Run it after you change `haconfig/engine/` or the state models.

The repo is public, so everything in `state.k` is public, such as the names of your rooms and devices, integration titles, device paths, and the app options that `task hass:import` writes. The import leaves out secrets and email addresses.

## Delivery

`task hass:deploy` uploads the rendered config to the Pi over SSH, then loads it into HA with a reload or a restart. It owns the paths that `task hass:diff` compares: `configuration.yaml`, `secrets.example.yaml`, `.gitignore`, and the package directory. Apart from its own `.hass-deploy/` directory, it never touches another path in the config directory, such as `secrets.yaml`, the UI files, `.storage`, or `custom_components`. It keeps every `secrets.yaml` inside `packages/`.

The deploy replaces each path that it owns as a whole. It deletes every file under `packages/` that the render lacks, and it drops hand edits to `configuration.yaml`. Port the ones you want to keep into `home/hass/` first, as [Live Diff](#live-diff) describes.

The deploy needs the SSH app that [Live Diff](#live-diff) describes, and an admin token in `HASS_TOKEN`, as [Registry State](#registry-state) describes. It runs these steps, and stops at the first failure:

1. It runs `task hass:check`, then diffs the render against the Pi as `task hass:diff` does. It stops when nothing changed. It also stops when the Pi's `secrets.yaml` lacks a referenced secret, because HA then fails to load the config.
2. It plans the reload. `homeassistant.reload_all` reloads the themes and every integration that has a reload action, such as `automation` and `script`. It also re-reads the `homeassistant:` block, but integrations read the location, the units, and the region only at startup. The plan prints a warning for each change that needs a restart.
3. It asks you to type `yes`. `YES=1` skips the question, and `DRY_RUN=1` stops before it.
4. It uploads the owned paths in one SSH session and takes a lock on the Pi. The Pi checks that its files still match the diff and that the upload arrived whole. It saves the old files to a tar under `.hass-deploy/backups/`, then swaps in the new files.
5. HA checks the config through its API. An error, or a warning that the check before the upload did not report, restores the backup and fails the deploy. Any other failure from the upload to this step, such as a dropped connection or Ctrl-C, also restores the backup.
6. It calls `homeassistant.reload_all`. With `RESTART=1`, HA restarts instead, and the task waits until HA runs again.
7. It checks that the Pi's owned files match the render, and lists each automation and script that became unavailable. It then releases the lock and keeps the five newest backups.

HA's API check reports YAML errors and core config errors, and most other problems only as warnings or in its log. `task hass:check` fails on those log lines too, and it runs first, so the deploy uploads only a config that passed it.

A deploy that dies without releasing its lock leaves the lock on the Pi, for example when the machine that runs it loses power. The next deploy waits until the lock is 30 minutes old. It then undoes the dead deploy by restoring that deploy's backup, and continues.

The `core` block in `home/hass/main.k` sets the location, the units, and the URLs from YAML. Before the first deploy, you must add the block's `!secret` names to the Pi's `secrets.yaml`. After the first deploy, HA locks the **General** settings, the **Network** URL settings, and the home zone in the UI, so you change them in `main.k`.

The first deploy also copies its backup to `.hass-deploy/original.tar`, which no deploy prunes, so the Pi's hand-made config stays recoverable. Each backup holds a copy of every `secrets.yaml` under `packages/`.

To undo a deploy:

1. Run the restore command that the deploy printed. It removes the owned paths and extracts that deploy's backup.
2. Run `ha core check` on the Pi.
3. Reload the YAML in **Developer tools** > **YAML**, or restart HA.
