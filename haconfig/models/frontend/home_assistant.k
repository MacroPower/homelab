import regex
import models.frontend.core
import models.frontend.state as hstate

# _RESERVED_INTEGRATIONS lists the top-level keys that HomeAssistantBackend or
# the packages write. `HomeAssistant.integrations` must not set them.
_RESERVED_INTEGRATIONS = ["default_config", "scene"] + _MODELLED_DOMAINS

schema HomeAssistant:
    """HomeAssistant is the root model of one Home Assistant configuration
    directory. The render turns it into `configuration.yaml`, one
    `packages/<name>.yaml` per package, `secrets.example.yaml`, and a
    `.gitignore`. The render requires exactly one HomeAssistant instance in the
    main package, and each variable that holds one adds an instance, even a
    `_`-prefixed variable.

    Attributes
    ----------
    core: core.Core, default is Undefined, optional.
        Core is the `homeassistant:` block. The render always sets its
        `packages` key.
    defaultConfig: bool, default is True, optional.
        DefaultConfig emits `default_config:`.
    uiIncludes: bool, default is True, optional.
        UiIncludes emits `automation: !include automations.yaml` and the
        matching `script` and `scene` lines, so automations, scripts, and
        scenes made in the UI keep working. The render never writes those
        files.
    packagesDir: str, default is "packages", optional.
        PackagesDir is the directory that the render writes packages into and
        that `!include_dir_named` loads them from.
    integrations: {str:any}, default is {}, optional.
        Integrations are extra top-level `configuration.yaml` keys, such as
        `http`, `recorder`, or `logger`, emitted verbatim. A key must not be
        `homeassistant`, `default_config`, a UI include key, or a domain that
        packages model, even with a label.
    packages: {str:Package}, default is Undefined, optional.
        Packages are keyed by package name, and each key must equal its
        Package's `name`. Build the map with
        `{_p.name: _p for _p in [hallway, kitchen]}`.
    secrets: {str:any}, default is {}, optional.
        Secrets declares every `!secret` name that the config references,
        mapped to a fake value of the type HA validates, such as a float for
        `latitude` or a URL for `internal_url`. The render fails on a reference
        to an undeclared name, and writes each referenced name with its fake
        value to `secrets.example.yaml`. Real values live only on the Home
        Assistant host. Names must match `[a-z0-9_]+`.
    deployGitignore: bool, default is True, optional.
        DeployGitignore emits a `.gitignore` for the files that HA writes at
        runtime, so the rendered directory can be the root of a deploy branch.
    state: hstate.State, default is Undefined, optional.
        State is the desired state of the registries in `.storage`, such as
        floors, areas, and labels. The render writes it to `state.json` next
        to the config directory, never into it, and `task hass:plan` and
        `task hass:apply` read it from there.

    Examples
    --------
    import haconfig.models.frontend

    config = frontend.HomeAssistant {
        core.name = "Home"
        packages = {_p.name: _p for _p in [hallway]}
    }
    """
    core?: core.Core
    defaultConfig?: bool = True
    uiIncludes?: bool = True
    packagesDir?: str = "packages"
    integrations?: {str:any} = {}
    packages?: {str:Package}
    secrets?: {str:any} = {}
    deployGitignore?: bool = True
    state?: hstate.State

    _misnamed: [str] = [_k for _k, _p in packages or {} if _p and _p.name != _k]
    _reservedIntegrations: [str] = [_k for _k in integrations or {} if _k.split(" ")[0] in _RESERVED_INTEGRATIONS]
    _badSecretNames: [str] = [_n for _n in secrets or {} if not regex.match(_n, r"^[a-z0-9_]+$")]

    check:
        not _misnamed, "each `packages` key must equal its Package name, got ${_misnamed}"
        not _reservedIntegrations, "integrations must not set ${_reservedIntegrations}; use the dedicated fields for `homeassistant`, `default_config` and the UI includes, and a package for a domain packages model"
        not _badSecretNames, "secret names must match [a-z0-9_]+, got ${_badSecretNames}"
