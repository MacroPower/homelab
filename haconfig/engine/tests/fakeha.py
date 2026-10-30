"""A fake HA that follows the registry rules of HA 2026.10.4.

It copies the rules that matter to a plan and an apply:
- name uniqueness by casefolded name without whitespace
  (normalized_name_base_registry.py)
- ids from the slugified name, with `_2` on a clash (IDManager)
- the cascades that clear a deleted floor, label, or category from areas,
  devices, and entities (area_registry.py, device_registry.py,
  entity_registry.py)
"""

from __future__ import annotations

import copy
import itertools
import re
from typing import Any

from hastate.client import HAError

REGISTRIES = {"area": ("areas", "area_id"), "floor": ("floors", "floor_id"), "label": ("labels", "label_id")}
DEFAULTS = {
    "areas": {"floor_id": None, "icon": None, "aliases": [], "labels": [], "picture": None, "temperature_entity_id": None, "humidity_entity_id": None},
    "floors": {"level": None, "icon": None, "aliases": []},
    "labels": {"color": None, "icon": None, "description": None},
}


def normalize_name(name: str) -> str:
    return re.sub(r"\s+", "", name.casefold())


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.casefold()).strip("_") or "unknown"


class FakeHA:
    ha_version = "fake"

    def __init__(self, areas=(), floors=(), labels=(), categories=None, entities=(), devices=()) -> None:
        self.data: dict[str, dict[str, dict[str, Any]]] = {"areas": {}, "floors": {}, "labels": {}}
        for coll, id_field, objects in (("areas", "area_id", areas), ("floors", "floor_id", floors), ("labels", "label_id", labels)):
            for obj in objects:
                self.data[coll][obj[id_field]] = DEFAULTS[coll] | obj
        self.categories: dict[str, dict[str, dict[str, Any]]] = {
            scope: {c["category_id"]: {"icon": None} | c for c in cats} for scope, cats in (categories or {}).items()
        }
        self.entities = [copy.deepcopy(e) for e in entities]
        self.devices = [copy.deepcopy(d) for d in devices]
        self.writes: list[tuple[str, dict[str, Any]]] = []
        self._ids = itertools.count(1)

    def names(self, coll: str, skip: str | None = None) -> set[str]:
        return {normalize_name(o["name"]) for i, o in self.data[coll].items() if i != skip}

    async def call(self, command: str, **fields: Any) -> Any:
        if not command.endswith("/list") and command != "get_states":
            self.writes.append((command, copy.deepcopy(fields)))
        if command == "get_states":
            return []
        if command == "config/entity_registry/list":
            return copy.deepcopy(self.entities)
        if command == "config/device_registry/list":
            return copy.deepcopy(self.devices)
        _, registry, op = command.split("/")
        if registry == "category_registry":
            return self._category(command, op, fields)
        coll, id_field = REGISTRIES[registry.removesuffix("_registry")]
        objects = self.data[coll]
        if op == "list":
            return [copy.deepcopy(o) for o in objects.values()]
        if op == "create":
            if any(v is None for v in fields.values()):
                raise HAError(command, "invalid_format", "null on create")
            name = fields.pop("name")
            if normalize_name(name) in self.names(coll):
                raise HAError(command, "invalid_info", f"The name {name} is already in use")
            base = new_id = slugify(name)
            for n in itertools.count(2):
                if new_id not in objects:
                    break
                new_id = f"{base}_{n}"
            objects[new_id] = DEFAULTS[coll] | {id_field: new_id, "name": name} | fields
            return copy.deepcopy(objects[new_id])
        if op == "update":
            obj = objects[fields.pop(id_field)]
            if "name" in fields and normalize_name(fields["name"]) in self.names(coll, skip=obj[id_field]):
                raise HAError(command, "invalid_info", f"The name {fields['name']} is already in use")
            obj.update(fields)
            return copy.deepcopy(obj)
        if op == "delete":
            obj_id = fields[id_field]
            del objects[obj_id]
            if coll == "floors":
                for a in self.data["areas"].values():
                    if a["floor_id"] == obj_id:
                        a["floor_id"] = None
            if coll == "labels":
                for holder in [*self.data["areas"].values(), *self.entities, *self.devices]:
                    holder["labels"] = [l for l in holder.get("labels", []) if l != obj_id]
            return None
        raise NotImplementedError(command)

    def _category(self, command: str, op: str, fields: dict[str, Any]) -> Any:
        cats = self.categories.setdefault(fields["scope"], {})
        if op == "list":
            return [copy.deepcopy(c) for c in cats.values()]
        if op == "create":
            if any(c["name"].casefold() == fields["name"].casefold() for c in cats.values()):
                raise HAError(command, "invalid_info", "name in use")
            category_id = f"01CAT{next(self._ids):04d}"
            cats[category_id] = {"category_id": category_id, "name": fields["name"], "icon": fields.get("icon")}
            return copy.deepcopy(cats[category_id])
        if op == "update":
            cats[fields["category_id"]].update({k: v for k, v in fields.items() if k in ("name", "icon")})
            return copy.deepcopy(cats[fields["category_id"]])
        if op == "delete":
            del cats[fields["category_id"]]
            for e in self.entities:
                if (e.get("categories") or {}).get(fields["scope"]) == fields["category_id"]:
                    del e["categories"][fields["scope"]]
            return None
        raise NotImplementedError(command)
