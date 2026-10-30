import regex

import models.frontend.common

# STATE_COLLECTIONS names the collections that `State.prune` accepts.
STATE_COLLECTIONS = ["floors", "areas", "labels", "categories"]

# LABEL_THEME_COLORS is `SUPPORTED_LABEL_THEME_COLORS` from
# `homeassistant/components/config/label_registry.py`.
LABEL_THEME_COLORS = [
    "primary", "accent", "disabled", "red", "pink", "purple", "deep-purple", "indigo", "blue", "light-blue", "cyan", "teal", "green", "light-green", "lime", "yellow", "amber", "orange", "deep-orange", "brown", "light-grey", "grey", "dark-grey", "blue-grey", "black", "white"
]

# normalizeName approximates the name key of HA's registries, which casefolds
# a name and removes its whitespace. Two names with the same key clash.
normalizeName = lambda name: str -> str {
    regex.replace(name.lower(), r"\s+", "")
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
        ignoring case and whitespace.
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
        ignoring case and whitespace.
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
        ignoring case and whitespace.
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
    prune?: [str] = []

    _collections: {str:any} = {
        floors = floors
        areas = areas
        labels = labels
        categories = categories
    }
    _badKeys: [str] = [
        "${_c}.${_k}" for _c in ["floors", "areas", "labels"] for _k in _collections[_c] or {} if not common.isSlug(_k)
    ] + [
        "categories.${_s}" for _s in categories or {} if not common.isSlug(_s)
    ] + [
        "categories.${_s}.${_k}" for _s, _cs in categories or {} for _k in _cs if not common.isSlug(_k)
    ]
    _badPrune: [str] = [_p for _p in prune or [] if _p not in STATE_COLLECTIONS or _collections[_p] in [Undefined, None]]
    _nameKeys: {str:[str]} = {
        _c: [normalizeName(_o.name) for _, _o in _collections[_c] or {}] for _c in ["floors", "areas", "labels"]
    }
    _duplicateNames: [str] = [
        "${_c}: ${_n}" for _c, _ns in _nameKeys for _i, _n in _ns if _n in _ns[_i + 1:]
    ] + [
        "categories.${_s}: ${_n}" for _s, _cs in categories or {} for _i, _n in [normalizeName(_o.name) for _, _o in _cs] if _n in [normalizeName(_o.name) for _, _o in _cs][_i + 1:]
    ]

    check:
        not _badKeys, "state keys must be slugs, got ${_badKeys}"
        not _badPrune, "prune must name managed collections from ${STATE_COLLECTIONS}, got ${_badPrune}"
        not _duplicateNames, "names must be unique within a collection, ignoring case and whitespace: ${_duplicateNames}"
