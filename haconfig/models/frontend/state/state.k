import regex

import models.frontend.common

# STATE_COLLECTIONS names the collections that `State.prune` accepts. The
# engine never deletes devices, entities, or integrations, so those
# collections are not in the list.
STATE_COLLECTIONS = ["floors", "areas", "labels", "categories", "apps", "appRepositories", "hacs"]

# DEVICE_ID matches a device registry id, a random hex string.
DEVICE_ID = r"^[0-9a-f]{32}$"

# LABEL_THEME_COLORS is `SUPPORTED_LABEL_THEME_COLORS` from
# `homeassistant/components/config/label_registry.py`.
LABEL_THEME_COLORS = [
    "primary", "accent", "disabled", "red", "pink", "purple", "deep-purple", "indigo", "blue", "light-blue", "cyan", "teal", "green", "light-green", "lime", "yellow", "amber", "orange", "deep-orange", "brown", "light-grey", "grey", "dark-grey", "blue-grey", "black", "white"
]

# normalizeName approximates the name key of HA's floor, area, and label
# registries, which casefolds a name and removes its spaces. Two names with
# the same key clash. The category registry compares names by case only.
normalizeName = lambda name: str -> str {
    name.lower().replace(" ", "")
}

# isIcon reports whether `icon` is unset, None, or an icon name such as
# `mdi:sofa`.
isIcon = lambda icon: any -> bool {
    icon in [Undefined, None] or ":" in icon
}

schema Floor:
    """Floor is one entry of HA's floor registry, and its map key is the floor
    id. The state owns every field of a declared floor, so an unset field
    clears that field in HA.

    Attributes
    ----------
    name: str, default is Undefined, required.
        Name is the display name. It must differ from every other floor name,
        ignoring case and spaces.
    level: int, default is Undefined, optional.
        Level is the floor number, such as 0 for the ground floor.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:home-floor-1`.
    aliases: [str], default is Undefined, optional.
        Aliases are other names that Assist matches.
    """
    name: str
    level?: int
    icon?: str
    aliases?: [str]

    _emptyAliases: [str] = [_a for _a in aliases or [] if not _a.strip()]

    check:
        name.strip(), "floor name must not be empty"
        isIcon(icon), "icon must look like `mdi:name`, got `${icon}`"
        not _emptyAliases, "aliases must not be empty strings"

schema Area:
    """Area is one entry of HA's area registry, and its map key is the area
    id. The state owns every field of a declared area, so an unset field
    clears that field in HA.

    Attributes
    ----------
    name: str, default is Undefined, required.
        Name is the display name. It must differ from every other area name,
        ignoring case and spaces.
    floor: str, default is Undefined, optional.
        Floor is the id of the area's floor.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:sofa`.
    aliases: [str], default is Undefined, optional.
        Aliases are other names that Assist matches.
    labels: [str], default is Undefined, optional.
        Labels are label ids. HA drops a label id that its label registry
        lacks, so the plan fails on one.
    picture: str, default is Undefined, optional.
        Picture is the URL of the area's picture.
    temperatureEntity: str, default is Undefined, optional.
        TemperatureEntity is a `sensor` entity with the `temperature` device
        class, shown as the area's temperature.
    humidityEntity: str, default is Undefined, optional.
        HumidityEntity is a `sensor` entity with the `humidity` device class,
        shown as the area's humidity.
    """
    name: str
    floor?: str
    icon?: str
    aliases?: [str]
    labels?: [str]
    picture?: str
    temperatureEntity?: str
    humidityEntity?: str

    _emptyAliases: [str] = [_a for _a in aliases or [] if not _a.strip()]
    _badLabels: [str] = [_l for _l in labels or [] if not common.isSlug(_l)]

    check:
        name.strip(), "area name must not be empty"
        floor in [Undefined, None] or common.isSlug(floor), "floor must be a floor id, got `${floor}`"
        isIcon(icon), "icon must look like `mdi:name`, got `${icon}`"
        not _emptyAliases, "aliases must not be empty strings"
        not _badLabels, "labels must be label ids, got ${_badLabels}"
        temperatureEntity in [Undefined, None] or temperatureEntity.startswith("sensor."), "temperatureEntity must be a sensor entity id, got `${temperatureEntity}`"
        humidityEntity in [Undefined, None] or humidityEntity.startswith("sensor."), "humidityEntity must be a sensor entity id, got `${humidityEntity}`"

schema Label:
    """Label is one entry of HA's label registry, and its map key is the label
    id. The state owns every field of a declared label, so an unset field
    clears that field in HA.

    Attributes
    ----------
    name: str, default is Undefined, required.
        Name is the display name. It must differ from every other label name,
        ignoring case and spaces.
    color: str, default is Undefined, optional.
        Color is `#RRGGBB` or a theme color in `LABEL_THEME_COLORS`.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:lightbulb`.
    description: str, default is Undefined, optional.
        Description is a longer text that the UI shows with the label.
    """
    name: str
    color?: str
    icon?: str
    description?: str

    check:
        name.strip(), "label name must not be empty"
        color in [Undefined, None] or color in LABEL_THEME_COLORS or regex.match(color, r"^#[0-9a-fA-F]{6}$"), "color must be #RRGGBB or one of ${LABEL_THEME_COLORS}, got `${color}`"
        isIcon(icon), "icon must look like `mdi:name`, got `${icon}`"

schema Category:
    """Category is one entry of HA's category registry. HA gives each category
    a random id, so the state matches a category by its name within its
    scope. Renaming a category in git creates a new category, and the old one
    stays until `prune` removes it.

    Attributes
    ----------
    name: str, default is Undefined, required.
        Name is the display name, unique within the scope, ignoring case.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:lightbulb`.
    """
    name: str
    icon?: str

    check:
        name.strip(), "category name must not be empty"
        isIcon(icon), "icon must look like `mdi:name`, got `${icon}`"

schema DeviceMatch:
    """DeviceMatch finds one device in HA's device registry. Set exactly one
    field. The plan fails when the match finds no device or more than one.

    Attributes
    ----------
    id: str, default is Undefined, optional.
        Id is the device registry id, which HA keeps when the integration
        removes the device and later adds it back. `task hass:import` writes
        this field, because the id reveals nothing about the hardware.
    identifier: [str], default is Undefined, optional.
        Identifier is one of the device's `[domain, value]` identifiers, such
        as `["zha", "00:12:4b:00:1c:a1:b2:c3"]`.
    connection: [str], default is Undefined, optional.
        Connection is one of the device's `[type, value]` connections, such as
        `["mac", "aa:bb:cc:dd:ee:ff"]`. The match ignores case.
    """
    id?: str
    identifier?: [str]
    connection?: [str]

    _set: [str] = [_n for _n, _v in {id = id, identifier = identifier, connection = connection} if _v not in [Undefined, None]]

    check:
        len(_set) == 1, "a device match must set exactly one of id, identifier, and connection, got ${_set}"
        id in [Undefined, None] or regex.match(id, DEVICE_ID), "match.id must be a 32-character hex device id, got `${id}`"
        identifier in [Undefined, None] or len(identifier) == 2, "match.identifier must be [domain, value], got ${identifier}"
        connection in [Undefined, None] or len(connection) == 2, "match.connection must be [type, value], got ${connection}"

schema Device:
    """Device holds the settings that you can change on one device in HA's
    device registry. The engine never creates or deletes a device. It manages
    only the fields that the device sets, so an unset field stays as it is in
    HA, and None clears the field.

    Attributes
    ----------
    match: DeviceMatch, default is Undefined, required.
        Match finds the device.
    name: str, default is Undefined, optional.
        Name is your name for the device. None restores the integration's
        name.
    area: str, default is Undefined, optional.
        Area is the id of the device's area. None removes the device from its
        area.
    labels: [str], default is Undefined, optional.
        Labels are label ids, and a set list is the whole list.
    disabled: bool, default is Undefined, optional.
        Disabled disables the device and its entities. False enables a device
        that you disabled. It cannot enable a device that its integration or
        config entry disabled.
    """
    match: DeviceMatch
    name?: str
    area?: str
    labels?: [str]
    disabled?: bool

    _badLabels: [str] = [_l for _l in labels or [] if not common.isSlug(_l)]

    check:
        area in [Undefined, None] or common.isSlug(area), "area must be an area id, got `${area}`"
        not _badLabels, "labels must be label ids, got ${_badLabels}"
        disabled is not None, "disabled must be True or False; leave it unset to keep HA's value"

schema EntityMatch:
    """EntityMatch finds an entity by the identity that its integration gives
    it, so the state can rename the entity id.

    Attributes
    ----------
    platform: str, default is Undefined, required.
        Platform is the integration that provides the entity, such as `hue`.
    uniqueId: str, default is Undefined, required.
        UniqueId is the entity's unique id. HA scopes it to the entity's
        domain and platform, so the plan matches it within the domain of the
        map key.
    """
    platform: str
    uniqueId: str

schema Entity:
    """Entity holds the settings that you can change on one entity in HA's
    entity registry, and its map key is the entity id. The engine never
    creates or deletes an entity. It manages only the fields that the entity
    sets, so an unset field stays as it is in HA, and None clears the field.

    Attributes
    ----------
    match: EntityMatch, default is Undefined, optional.
        Match finds the entity under another entity id and renames it to the
        map key. Without it, the map key finds the entity.
    name: str, default is Undefined, optional.
        Name is your name for the entity. None restores the integration's
        name.
    icon: str, default is Undefined, optional.
        Icon is an icon name, such as `mdi:lamp`. None restores the
        integration's icon.
    area: str, default is Undefined, optional.
        Area is the id of the entity's own area. None makes the entity follow
        its device's area.
    labels: [str], default is Undefined, optional.
        Labels are label ids, and a set list is the whole list.
    aliases: [str], default is Undefined, optional.
        Aliases are other names that Assist matches, in order. HA strips
        each alias. The entity's own name keeps its place among them.
    hidden: bool, default is Undefined, optional.
        Hidden hides the entity from auto-generated dashboards. False shows
        an entity that you hid.
    disabled: bool, default is Undefined, optional.
        Disabled disables the entity. False enables an entity that you
        disabled.
    deviceClass: str, default is Undefined, optional.
        DeviceClass overrides the integration's device class, such as
        `window` for a `binary_sensor`. None restores the integration's
        device class.
    categories: {str:str}, default is Undefined, optional.
        Categories map a category scope, such as `automation`, to a category
        name in that scope. A set map is the whole map.
    """
    match?: EntityMatch
    name?: str
    icon?: str
    area?: str
    labels?: [str]
    aliases?: [str]
    hidden?: bool
    disabled?: bool
    deviceClass?: str
    categories?: {str:str}

    _badLabels: [str] = [_l for _l in labels or [] if not common.isSlug(_l)]
    _emptyAliases: [str] = [_a for _a in aliases or [] if not _a.strip()]
    _nulls: [str] = [_n for _n, _v in {hidden = hidden, disabled = disabled} if _v is None]
    _nullCategories: [str] = [_s for _s, _c in categories or {} if _c is None]

    check:
        isIcon(icon), "icon must look like `mdi:name`, got `${icon}`"
        area in [Undefined, None] or common.isSlug(area), "area must be an area id, got `${area}`"
        not _badLabels, "labels must be label ids, got ${_badLabels}"
        not _emptyAliases, "aliases must not be empty strings"
        not _nulls, "${_nulls} must be True or False; leave a field unset to keep HA's value"
        not _nullCategories, "categories must map each scope to a name; leave the scope out to remove its category, got None for ${_nullCategories}"

schema Integration:
    """Integration is one config entry that the instance must have. The
    engine never adds, removes, or reconfigures an integration. The plan
    warns about each declared integration that HA lacks, and lists each live
    one that the state lacks.

    Attributes
    ----------
    domain: str, default is Undefined, required.
        Domain is the integration's domain, such as `hue`.
    entryId: str, default is Undefined, optional.
        EntryId is the config entry id. With it, the state can rename the
        entry. Without it, the plan finds the entry by `domain` and `title`.
    title: str, default is Undefined, optional.
        Title is the entry's name in the UI. It is required without
        `entryId`.
    disabled: bool, default is Undefined, optional.
        Disabled disables the entry and every device and entity it provides.
    disableNewEntities: bool, default is Undefined, optional.
        DisableNewEntities adds new entities from the entry disabled.
    disablePolling: bool, default is Undefined, optional.
        DisablePolling stops the entry from polling for updates.
    """
    domain: str
    entryId?: str
    title?: str
    disabled?: bool
    disableNewEntities?: bool
    disablePolling?: bool

    _nulls: [str] = [_n for _n, _v in {entryId = entryId, title = title, disabled = disabled, disableNewEntities = disableNewEntities, disablePolling = disablePolling} if _v is None]

    check:
        entryId not in [Undefined, None] or title not in [Undefined, None], "an integration needs entryId or title to match its config entry"
        regex.match(domain, r"^[a-z0-9_]+$"), "domain must be an integration domain, got `${domain}`"
        not _nulls, "${_nulls} must not be None, which HA rejects; leave a field unset to keep HA's value"

# APP_SLUG matches a Supervisor app slug, such as `core_mosquitto`,
# `a0d7b954_ssh`, or `core_speech-to-phrase`, with the characters that the
# Supervisor accepts.
APP_SLUG = r"^[-_.A-Za-z0-9]+$"

# HACS_REPOSITORY matches a GitHub repository name, `owner/repo`. HACS
# accepts only letters, digits, and hyphens in the owner, as GitHub does.
HACS_REPOSITORY = r"^[A-Za-z0-9-]+/[A-Za-z0-9_.-]+$"

# HACS_CATEGORIES are the HACS categories a repository can belong to.
HACS_CATEGORIES = ["integration", "plugin", "theme", "python_script", "template", "appdaemon"]

schema App:
    """App is one Supervisor app, keyed by its slug. The state installs a
    declared app that HA lacks, and uninstalls a live one that it lacks only
    when `prune` names `apps`. It manages only the fields that the app sets.

    Attributes
    ----------
    version: str, default is Undefined, optional.
        Version pins the app's version. The Supervisor installs and updates
        only to the latest version in its store, so the apply updates the app
        when the store offers exactly this version, and the plan warns when
        the store offers another one.
    options: {str:any}, default is Undefined, optional.
        Options are the app's configuration options. The state manages each
        top-level key it sets, and a set key holds its whole value, so a map
        lists every key it needs. To restore an option's default, set the
        default value, because the Supervisor reports a removed key with its
        default. Pass a secret with `tags.secret(name)`, which the Supervisor
        reads from the Pi's `secrets.yaml`, so the value never enters git.
    boot: "auto" | "manual", default is Undefined, optional.
        Boot starts the app when the host boots.
    autoUpdate: bool, default is Undefined, optional.
        AutoUpdate lets the Supervisor update the app on its own.
    watchdog: bool, default is Undefined, optional.
        Watchdog restarts the app when it crashes.
    network: {str:any}, default is Undefined, optional.
        Network maps a container port, such as `22/tcp` or `8080`, to a host
        port, or to None to close it. The state manages each port it sets.
    ingressPanel: bool, default is Undefined, optional.
        IngressPanel shows the app in the sidebar.
    started: bool, default is Undefined, optional.
        Started starts or stops the app. Leave it unset for an app that runs
        once at startup, such as Let's Encrypt, which stops on its own.
    """
    version?: str
    options?: {str:any}
    boot?: "auto" | "manual"
    autoUpdate?: bool
    watchdog?: bool
    network?: {str:any}
    ingressPanel?: bool
    started?: bool

    _badPorts: [str] = [_p for _p, _v in network or {} if not regex.match(_p, r"^\d+(/(tcp|udp))?$") or (_v not in [None] and typeof(_v) != "int")]
    _nullOptions: [str] = [_k for _k, _v in options or {} if _v is None]
    _nulls: [str] = [_n for _n, _v in {version = version, options = options, boot = boot, autoUpdate = autoUpdate, watchdog = watchdog, network = network, ingressPanel = ingressPanel, started = started} if _v is None]

    check:
        not _badPorts, "network keys must look like `22/tcp` or `22` and map to a port number or None, got ${_badPorts}"
        not _nullOptions, "options ${_nullOptions} are None; set the default value instead, because the Supervisor restores a removed option's default"
        not _nulls, "${_nulls} must not be None; leave a field unset to keep the Supervisor's value"

schema HacsRepository:
    """HacsRepository is one repository that HACS installs, keyed by its
    GitHub name, `owner/repo`. The state adds a custom repository that HACS
    lacks, and removes a live one that it lacks only when `prune` names
    `hacs`.

    Attributes
    ----------
    category: str, default is Undefined, required.
        Category is the HACS category, one of `HACS_CATEGORIES`.
    version: str, default is Undefined, required.
        Version is the release tag, such as `v1.13.1`, or a full 40-character
        commit sha for a repository without releases.
    """
    category: str
    version: str

    check:
        category in HACS_CATEGORIES, "category must be one of ${HACS_CATEGORIES}, got `${category}`"
        version.strip(), "version must not be empty"

schema Http:
    """Http is HA's HTTP server config, which HA keeps in `.storage/http`.
    HA replaces the whole config on every change, so the state owns every
    field, and an unset field takes HA's default. More info:
    https://www.home-assistant.io/integrations/http/

    The apply stages the config, restarts HA, reconnects, and confirms the
    config. HA restores the previous config 5 minutes after the restart
    unless the apply confirms it, so a config that locks the engine out
    reverts on its own.

    Attributes
    ----------
    serverPort: int, default is Undefined, optional.
        ServerPort is the port HA listens on. HA's default is 8123, or 80 on
        HA OS, where HA runs under the Supervisor.
    serverHost: [str], default is Undefined, optional.
        ServerHost lists the addresses HA binds. HA binds every address by
        default.
    sslCertificate: str, default is Undefined, optional.
        SslCertificate is the path of the certificate chain on the HA host,
        such as `/ssl/fullchain.pem`. With it, HA serves only HTTPS.
    sslKey: str, default is Undefined, optional.
        SslKey is the path of the certificate's private key on the HA host.
        Without it, HA reads the key from the certificate file. HA ignores it
        without `sslCertificate`.
    sslPeerCertificate: str, default is Undefined, optional.
        SslPeerCertificate is the path of a CA certificate that every client
        must present a certificate from. The engine cannot present one.
    sslProfile: "modern" | "intermediate", default is Undefined, optional.
        SslProfile selects the TLS ciphers. HA's default is `modern`.
    corsAllowedOrigins: [str], default is Undefined, optional.
        CorsAllowedOrigins lists the origins that may call HA's API from a
        browser. HA's default is `https://cast.home-assistant.io`.
    useXForwardedFor: bool, default is Undefined, optional.
        UseXForwardedFor reads the client address from a reverse proxy's
        `X-Forwarded-For` header. It requires `trustedProxies`.
    trustedProxies: [str], default is Undefined, optional.
        TrustedProxies lists the proxy addresses or networks, such as
        `10.0.0.0/24`, whose forwarded headers HA trusts.
    ipBanEnabled: bool, default is Undefined, optional.
        IpBanEnabled bans an address after failed logins. HA's default is
        True.
    loginAttemptsThreshold: int, default is Undefined, optional.
        LoginAttemptsThreshold is the number of failed logins before a ban,
        or -1 to never ban. HA's default is -1.
    useXFrameOptions: bool, default is Undefined, optional.
        UseXFrameOptions stops other sites from framing HA's frontend. HA's
        default is True.
    """
    serverPort?: int
    serverHost?: [str]
    sslCertificate?: str
    sslKey?: str
    sslPeerCertificate?: str
    sslProfile?: "modern" | "intermediate"
    corsAllowedOrigins?: [str]
    useXForwardedFor?: bool
    trustedProxies?: [str]
    ipBanEnabled?: bool
    loginAttemptsThreshold?: int
    useXFrameOptions?: bool

    check:
        serverPort in [Undefined, None] or 1 <= serverPort <= 65535, "serverPort must lie between 1 and 65535, inclusive, got ${serverPort}"
        not useXForwardedFor or trustedProxies, "useXForwardedFor needs at least one trusted proxy"
        loginAttemptsThreshold in [Undefined, None] or loginAttemptsThreshold >= -1, "loginAttemptsThreshold must be -1 or more, got ${loginAttemptsThreshold}"
        serverHost in [Undefined, None] or len(serverHost) > 0, "serverHost must list at least one address, or stay unset"

schema State:
    """State is the desired state of the HA registries that live in
    `.storage`. `task hass:plan` compares it with the live instance, and
    `task hass:apply` applies the difference.

    Each collection that the state sets is managed. The plan lists every live
    object that a managed collection lacks, and it deletes those objects only
    when `prune` names the collection. The engine never touches a collection
    that the state leaves unset.

    Attributes
    ----------
    floors: {str:Floor}, default is Undefined, optional.
        Floors are keyed by floor id.
    areas: {str:Area}, default is Undefined, optional.
        Areas are keyed by area id.
    labels: {str:Label}, default is Undefined, optional.
        Labels are keyed by label id.
    categories: {str:{str:Category}}, default is Undefined, optional.
        Categories are keyed by scope, such as `automation`, `script`, or
        `helpers`, then by a key of your choice.
    devices: {str:Device}, default is Undefined, optional.
        Devices are keyed by a slug of your choice.
    entities: {str:Entity}, default is Undefined, optional.
        Entities are keyed by entity id.
    integrations: {str:Integration}, default is Undefined, optional.
        Integrations are keyed by a slug of your choice.
    apps: {str:App}, default is Undefined, optional.
        Apps are keyed by Supervisor app slug.
    appRepositories: [str], default is Undefined, optional.
        AppRepositories are the URLs of the third-party app repositories that
        the Supervisor store reads. The built-in repositories are always
        present.
    hacs: {str:HacsRepository}, default is Undefined, optional.
        Hacs holds the HACS repositories, keyed by `owner/repo`.
    http: Http, default is Undefined, optional.
        Http is HA's HTTP server config. Set it here instead of the YAML
        `http:` key, which HA ignores after its first boot on 2026.8 or later.
    prune: [str], default is [], optional.
        Prune names the collections in which the apply deletes live objects
        that the state lacks. Each name must be a managed collection in
        `STATE_COLLECTIONS`.

    Examples
    --------
    import haconfig.models.frontend.state as hstate

    hass_state = hstate.State {
        floors.ground = {name = "Ground Floor", level = 0}
        areas.living_room = {name = "Living Room", floor = "ground"}
        prune = ["areas"]
    }
    """
    floors?: {str:Floor}
    areas?: {str:Area}
    labels?: {str:Label}
    categories?: {str:{str:Category}}
    devices?: {str:Device}
    entities?: {str:Entity}
    integrations?: {str:Integration}
    apps?: {str:App}
    appRepositories?: [str]
    hacs?: {str:HacsRepository}
    http?: Http
    prune?: [str] = []

    _collections: {str:any} = {
        floors = floors
        areas = areas
        labels = labels
        categories = categories
        apps = apps
        appRepositories = appRepositories
        hacs = hacs
    }
    _badKeys: [str] = [
        "${_c}.${_k}" for _c in ["floors", "areas", "labels"] for _k in _collections[_c] or {} if not common.isSlug(_k)
    ] + [
        "categories.${_s}" for _s in categories or {} if not common.isSlug(_s)
    ] + [
        "categories.${_s}.${_k}" for _s, _cs in categories or {} for _k in _cs or {} if not common.isSlug(_k)
    ] + [
        "${_c}.${_k}" for _c, _m in {devices = devices, integrations = integrations} for _k in _m or {} if not common.isSlug(_k)
    ] + [
        "entities.${_k}" for _k in entities or {} if not regex.match(_k, common.ENTITY_ID)
    ] + [
        "apps.${_k}" for _k in apps or {} if not regex.match(_k, APP_SLUG)
    ] + [
        "hacs.${_k}" for _k in hacs or {} if not regex.match(_k, HACS_REPOSITORY)
    ]
    _hacsNames: [str] = [_k.lower() for _k, _r in hacs or {} if _r is not None]
    _duplicateRepositories: [str] = [_n for _i, _n in _hacsNames if _n in _hacsNames[_i + 1:]]
    _deviceIds: [str] = [_d.match.id for _, _d in devices or {} if _d is not None and _d.match.id not in [Undefined, None]]
    _sharedMatches: [str] = [_n for _i, _n in _deviceIds if _n in _deviceIds[_i + 1:]]
    _badPrune: [str] = [_p for _p in prune or [] if _p not in STATE_COLLECTIONS or _collections[_p] in [Undefined, None]]
    _badRepositories: [str] = [_u for _u in appRepositories or [] if not _u or not _u.strip()]
    _nameKeys: {str:[str]} = {
        _c: [normalizeName(_o.name) for _, _o in _collections[_c] or {} if _o is not None] for _c in ["floors", "areas", "labels"]
    }
    _categoryNames: {str:[str]} = {_s: [_o.name.lower() for _, _o in _cs or {} if _o is not None] for _s, _cs in categories or {}}
    _duplicateNames: [str] = [
        "${_c}: ${_n}" for _c, _ns in _nameKeys for _i, _n in _ns if _n in _ns[_i + 1:]
    ] + [
        "categories.${_s}: ${_n}" for _s, _ns in _categoryNames for _i, _n in _ns if _n in _ns[_i + 1:]
    ]

    check:
        not _badKeys, "state keys must be slugs, and entity keys must be entity ids, got ${_badKeys}"
        not _sharedMatches, "two devices match the same device id: ${_sharedMatches}"
        not _duplicateRepositories, "HACS repository names ignore case, so these keys repeat one: ${_duplicateRepositories}"
        not _badPrune, "prune must name managed collections from ${STATE_COLLECTIONS}, got ${_badPrune}"
        not _duplicateNames, "names must be unique within a collection, ignoring case, and for floors, areas, and labels, spaces: ${_duplicateNames}"
        appRepositories is not None, "appRepositories must be a list; leave it unset to leave the repositories unmanaged"
        not _badRepositories, "appRepositories must hold repository URLs, got ${_badRepositories}"
