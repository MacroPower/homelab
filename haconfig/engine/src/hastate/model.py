"""The types and helpers that the planner, the executor, and the report share."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any

STATE_FORMAT = 1
"""The state document version that this engine reads."""


@dataclass(frozen=True)
class Registry:
    """Registry describes one id-keyed HA registry and the fields the state owns."""

    collection: str
    prefix: str
    id_field: str
    fields: tuple[str, ...]
    set_fields: frozenset[str] = frozenset()

    @property
    def noun(self) -> str:
        return self.collection.removesuffix("s")


LABELS = Registry("labels", "config/label_registry", "label_id", ("name", "color", "icon", "description"))
FLOORS = Registry("floors", "config/floor_registry", "floor_id", ("name", "level", "icon", "aliases"), frozenset({"aliases"}))
AREAS = Registry(
    "areas",
    "config/area_registry",
    "area_id",
    ("name", "floor_id", "icon", "aliases", "labels", "picture", "temperature_entity_id", "humidity_entity_id"),
    frozenset({"aliases", "labels"}),
)

REGISTRIES = (LABELS, FLOORS, AREAS)
"""The id-keyed registries in apply order. Each one references only the registries before it."""

CATEGORIES = "categories"
CATEGORY_PREFIX = "config/category_registry"
CATEGORY_FIELDS = ("name", "icon")
CATEGORY_SCOPES = ("automation", "script", "scene", "helpers")
"""The category scopes that HA's frontend uses. A managed categories collection always covers them."""

AREA_SENSORS = {"temperature_entity_id": "temperature", "humidity_entity_id": "humidity"}
"""The area fields that name a sensor, mapped to the device class HA requires."""

CREATE_SUFFIX = " ~"
"""The suffix of a create's temporary name. HA's slugify drops it, so the object gets its key as its id."""

RENAME_SUFFIX = " ~haconfig~"
"""The suffix of the temporary name that frees an object's old name during an apply."""


def create_name(key: str) -> str:
    """Return the temporary name that a create of KEY uses, which HA slugifies to KEY."""
    return key + CREATE_SUFFIX


def rename_name(key: str) -> str:
    """Return the temporary name that moves object KEY out of the way of another object's new name."""
    return key + RENAME_SUFFIX


class StateError(Exception):
    """StateError means that the planner cannot read the state document."""


@dataclass
class Live:
    """Live is a snapshot of the registries that a plan reads.

    `registries` maps a collection name to HA's list result, and `categories`
    maps a scope to its list. `states` maps an entity id to its state object,
    and is None when no area names a sensor. `entities` and `devices` hold
    the entity and device registries, and are None when the plan needs
    neither. `entity_details` maps an entity id to its extended registry
    entry, which alone carries `aliases` and the user's `device_class`.
    `config_entries` holds the config entries when the state declares
    integrations. `apps` lists the installed apps, `app_info` maps an app
    slug to its info, `app_store` maps the slug of a declared app that is not
    installed to its store entry, and `app_repositories` lists the store's
    repositories. `hacs` lists the HACS repositories and `hacs_info` holds
    HACS's status, or None when HACS is not installed. `http` holds the
    result of `http/config`.
    """

    ha_version: str
    registries: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    categories: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    states: dict[str, dict[str, Any]] | None = None
    entities: list[dict[str, Any]] | None = None
    devices: list[dict[str, Any]] | None = None
    entity_details: dict[str, dict[str, Any]] | None = None
    config_entries: list[dict[str, Any]] | None = None
    apps: list[dict[str, Any]] | None = None
    app_info: dict[str, dict[str, Any]] | None = None
    app_store: dict[str, dict[str, Any]] | None = None
    app_repositories: list[dict[str, Any]] | None = None
    hacs: list[dict[str, Any]] | None = None
    hacs_info: dict[str, Any] | None = None
    http: dict[str, Any] | None = None


@dataclass
class Change:
    """Change is one planned operation on one registry object.

    `action` is create, update, delete, unmanaged, or missing, which marks a
    declared integration that HA lacks. `diff` maps each field
    to its live and desired value, with None as the live value of a create.
    `target` is the live id of an update or a delete, and the desired fields of
    a create. `notes` lists the side effects of a delete outside the state,
    such as the entities that lose a label.
    """

    action: str
    collection: str
    key: str
    name: str
    diff: dict[str, tuple[Any, Any]] = field(default_factory=dict)
    target: Any = None
    scope: str | None = None
    notes: list[str] = field(default_factory=list)
    sensitive: set[str] = field(default_factory=set)
    """sensitive names the diff fields whose values the report never prints."""
    sent: dict[str, Any] = field(default_factory=dict)
    """sent maps a diff field to the value the apply sends, when it differs from the shown value."""

    @property
    def address(self) -> str:
        if self.scope is not None:
            return f"{self.collection}.{self.scope}.{self.key}"
        return f"{self.collection}.{self.key}"


@dataclass
class Plan:
    """Plan lists the changes, the problems that block an apply, and the warnings that do not."""

    ha_version: str
    changes: list[Change] = field(default_factory=list)
    problems: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def actions(self) -> list[Change]:
        return [c for c in self.changes if c.action in ("create", "update", "delete")]

    def count(self, action: str) -> int:
        return sum(1 for c in self.changes if c.action == action)

    def fingerprint(self) -> str:
        """Return a string that two plans share exactly when they hold the same actions."""
        return json.dumps([[c.action, c.address, c.diff, c.target] for c in self.actions], sort_keys=True, default=str)


def name_key(name: str) -> str:
    """Return the key that HA's floor, area, and label registries compare names by: casefolded, without spaces."""
    return name.casefold().replace(" ", "")


def normalize(value: Any, as_set: bool) -> Any:
    """Return VALUE in the form HA stores it, so two equal values compare equal.

    A set field becomes a sorted list without duplicates or blank strings. HA
    stores area and floor aliases and labels as sets, so their order carries
    no meaning.
    """
    if as_set:
        return sorted({v.strip() for v in value or [] if isinstance(v, str) and v.strip()})
    if value == "":
        return None
    return value


def category_key(name: str) -> str:
    """Return the key that HA's category registry compares names by: casefolded only."""
    return name.casefold()


def is_empty(value: Any) -> bool:
    return value is None or value == [] or value == ""


def check_format(desired: dict[str, Any]) -> None:
    if desired.get("format") != STATE_FORMAT:
        raise StateError(f"state format {desired.get('format')!r} is not {STATE_FORMAT}; render the state with this haconfig version")
