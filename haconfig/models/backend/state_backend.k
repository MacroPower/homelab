import models.frontend.state as hstate

# STATE_FORMAT is the version of the state document. The engine refuses a
# document with another version.
STATE_FORMAT = 1

# STATE_GENERATOR marks a state document as haconfig's. The render's splitter
# overwrites or removes a state file only when it carries this marker.
STATE_GENERATOR = "haconfig"

# orNone returns `v`, or None when `v` is Undefined.
orNone = lambda v: any -> any {
    None if v is Undefined else v
}

schema StateBackend[inputConfig: hstate.State]:
    """
    StateBackend converts the front-end `State` into the state document that
    the engine reads, and places it in the `data` attribute. Field names are
    the names that HA's WebSocket registry commands take. A declared floor,
    area, label, or category carries every field it owns, with None or [] for
    an unset field, so the engine clears what git does not set. A device,
    entity, or integration carries only the fields it sets, so the engine
    leaves the others as they are.
    """
    config: hstate.State = inputConfig

    data: {str:any} = {
        format = STATE_FORMAT
        generator = STATE_GENERATOR
        if config.floors is not Undefined:
            floors = {
                _k: {
                    name = _f.name
                    level = orNone(_f.level)
                    icon = orNone(_f.icon)
                    aliases = _f.aliases or []
                } for _k, _f in config.floors if _f is not None
            }
        if config.areas is not Undefined:
            areas = {
                _k: {
                    name = _a.name
                    floor_id = orNone(_a.floor)
                    icon = orNone(_a.icon)
                    aliases = _a.aliases or []
                    labels = _a.labels or []
                    picture = orNone(_a.picture)
                    temperature_entity_id = orNone(_a.temperatureEntity)
                    humidity_entity_id = orNone(_a.humidityEntity)
                } for _k, _a in config.areas if _a is not None
            }
        if config.labels is not Undefined:
            labels = {
                _k: {
                    name = _l.name
                    color = orNone(_l.color)
                    icon = orNone(_l.icon)
                    description = orNone(_l.description)
                } for _k, _l in config.labels if _l is not None
            }
        if config.categories is not Undefined:
            categories = {
                _s: {_k: {name = _c.name, icon = orNone(_c.icon)} for _k, _c in _cs or {} if _c is not None} for _s, _cs in config.categories
            }
        if config.devices is not Undefined:
            devices = {
                _k: {
                    # A match field that is None counts as unset, so only the set one goes in.
                    match = {_f: _v for _f, _v in {id = _d.match.id, identifier = _d.match.identifier, connection = _d.match.connection} if _v is not None}
                    name_by_user = _d.name
                    area_id = _d.area
                    labels = [] if _d.labels is None else _d.labels
                    disabled = _d.disabled
                } for _k, _d in config.devices if _d is not None
            }
        if config.entities is not Undefined:
            entities = {
                _k: {
                    if _e.match not in [Undefined, None]:
                        match = {platform = _e.match.platform, unique_id = _e.match.uniqueId}
                    name = _e.name
                    icon = _e.icon
                    area_id = _e.area
                    # None clears a list or a map, so it goes in as an empty one.
                    labels = [] if _e.labels is None else _e.labels
                    aliases = [] if _e.aliases is None else _e.aliases
                    hidden = _e.hidden
                    disabled = _e.disabled
                    device_class = _e.deviceClass
                    categories = {} if _e.categories is None else _e.categories
                } for _k, _e in config.entities if _e is not None
            }
        if config.integrations is not Undefined:
            integrations = {
                _k: {
                    domain = _i.domain
                    entry_id = _i.entryId
                    title = _i.title
                    disabled = _i.disabled
                    pref_disable_new_entities = _i.disableNewEntities
                    pref_disable_polling = _i.disablePolling
                } for _k, _i in config.integrations if _i is not None
            }
        if config.apps is not Undefined:
            apps = {
                _k: {
                    version = _a.version
                    options = _a.options
                    boot = _a.boot
                    auto_update = _a.autoUpdate
                    watchdog = _a.watchdog
                    network = _a.network
                    ingress_panel = _a.ingressPanel
                    started = _a.started
                } for _k, _a in config.apps if _a is not None
            }
        if config.appRepositories is not Undefined:
            app_repositories = config.appRepositories
        if config.hacs is not Undefined:
            hacs = {_k: {category = _r.category, version = _r.version} for _k, _r in config.hacs if _r is not None}
        if config.http is not Undefined:
            http = {
                server_port = config.http.serverPort
                server_host = config.http.serverHost
                ssl_certificate = config.http.sslCertificate
                ssl_key = config.http.sslKey
                ssl_peer_certificate = config.http.sslPeerCertificate
                ssl_profile = config.http.sslProfile
                cors_allowed_origins = config.http.corsAllowedOrigins
                use_x_forwarded_for = config.http.useXForwardedFor
                trusted_proxies = config.http.trustedProxies
                ip_ban_enabled = config.http.ipBanEnabled
                login_attempts_threshold = config.http.loginAttemptsThreshold
                use_x_frame_options = config.http.useXFrameOptions
            }
        prune = sorted([{appRepositories = "app_repositories"}[_p] if _p == "appRepositories" else _p for _p in config.prune or []])
    }
