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
    an unset field, so the engine clears what git does not set.
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
                } for _k, _f in config.floors
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
                } for _k, _a in config.areas
            }
        if config.labels is not Undefined:
            labels = {
                _k: {
                    name = _l.name
                    color = orNone(_l.color)
                    icon = orNone(_l.icon)
                    description = orNone(_l.description)
                } for _k, _l in config.labels
            }
        if config.categories is not Undefined:
            categories = {
                _s: {_k: {name = _c.name, icon = orNone(_c.icon)} for _k, _c in _cs} for _s, _cs in config.categories
            }
        prune = sorted(config.prune or [])
    }
