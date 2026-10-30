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


ENTITY_DEFAULTS = {
    "name": None, "icon": None, "area_id": None, "labels": [], "aliases": [], "hidden_by": None, "disabled_by": None,
    "device_class": None, "categories": {}, "device_id": None, "original_name": None, "platform": "demo", "unique_id": None,
}
DEVICE_DEFAULTS = {"name": None, "name_by_user": None, "area_id": None, "labels": [], "disabled_by": None, "identifiers": [], "connections": []}
ENTRY_DEFAULTS = {"source": "user", "disabled_by": None, "pref_disable_new_entities": False, "pref_disable_polling": False}


def normalize_name(name: str) -> str:
    return re.sub(r"\s+", "", name.casefold())


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.casefold()).strip("_") or "unknown"


STORE_FIELDS = ("name", "slug", "version_latest", "repository", "installed", "available")
"""The fields of a real `/store/addons/{slug}` entry that the engine reads."""


class FakeHA:
    ha_version = "fake"

    def __init__(self, areas=(), floors=(), labels=(), categories=None, entities=(), devices=(), entries=(),
                 apps=None, store=None, repositories=(), hacs=None, http=None) -> None:
        self.data: dict[str, dict[str, dict[str, Any]]] = {"areas": {}, "floors": {}, "labels": {}}
        for coll, id_field, objects in (("areas", "area_id", areas), ("floors", "floor_id", floors), ("labels", "label_id", labels)):
            for obj in objects:
                self.data[coll][obj[id_field]] = DEFAULTS[coll] | obj
        self.categories: dict[str, dict[str, dict[str, Any]]] = {
            scope: {c["category_id"]: {"icon": None} | c for c in cats} for scope, cats in (categories or {}).items()
        }
        self.entities = [ENTITY_DEFAULTS | copy.deepcopy(e) for e in entities]
        self.devices = [DEVICE_DEFAULTS | copy.deepcopy(d) for d in devices]
        self.entries = [ENTRY_DEFAULTS | copy.deepcopy(e) for e in entries]
        # apps maps a slug to its info. store maps a slug to its store entry.
        self.apps = copy.deepcopy(apps) if apps is not None else None
        self.store = copy.deepcopy(store or {})
        self.repositories = [copy.deepcopy(r) for r in repositories]
        self.hacs_repos = copy.deepcopy(hacs) if hacs is not None else None
        self.http = copy.deepcopy(http)
        self.writes: list[tuple[str, dict[str, Any]]] = []
        self._ids = itertools.count(1)

    async def supervisor(self, method: str, endpoint: str, data: Any = None, timeout: float = 60.0) -> Any:
        fields: dict[str, Any] = {"endpoint": endpoint, "method": method, "timeout": timeout}
        if data is not None:
            fields["data"] = data
        return await self.call("supervisor/api", **fields)

    def names(self, coll: str, skip: str | None = None) -> set[str]:
        return {normalize_name(o["name"]) for i, o in self.data[coll].items() if i != skip}

    async def call(self, command: str, *, wait: float | None = None, **fields: Any) -> Any:
        if not command.endswith("/list") and command != "get_states":
            self.writes.append((command, copy.deepcopy(fields)))
        if command == "get_states":
            return []
        if command == "supervisor/api":
            if self.apps is None:
                raise HAError(command, "unknown_command", "Unknown command.")
            return self._supervisor(fields["method"], fields["endpoint"], fields.get("data"))
        if command.startswith("hacs/"):
            return self._hacs(command, fields)
        if command == "http/config":
            return copy.deepcopy(self.http)
        if command == "config/entity_registry/list":
            return [{k: v for k, v in e.items() if k not in ("aliases", "device_class")} for e in copy.deepcopy(self.entities)]
        if command == "config/entity_registry/get_entries":
            by_id = {e["entity_id"]: e for e in self.entities}
            return {i: copy.deepcopy(by_id.get(i)) for i in fields["entity_ids"]}
        if command == "config/entity_registry/update":
            return self._entity_update(command, fields)
        if command == "config/device_registry/list":
            return copy.deepcopy(self.devices)
        if command == "config/device_registry/update":
            return self._device_update(fields)
        if command == "config_entries/get":
            return copy.deepcopy(self.entries)
        if command == "config_entries/update":
            entry = next(e for e in self.entries if e["entry_id"] == fields["entry_id"])
            entry.update({k: v for k, v in fields.items() if k != "entry_id"})
            return {"config_entry": copy.deepcopy(entry), "require_restart": False}
        if command == "config_entries/disable":
            entry = next(e for e in self.entries if e["entry_id"] == fields["entry_id"])
            entry["disabled_by"] = fields["disabled_by"]
            # HA enables the devices that the entry disabled, and disables a
            # device when every entry it belongs to is disabled.
            off = {e["entry_id"] for e in self.entries if e["disabled_by"]}
            for d in self.devices:
                own = d.get("config_entries") or []
                if entry["entry_id"] not in own:
                    continue
                if entry["disabled_by"] is None and d["disabled_by"] == "config_entry":
                    self._device_update({"device_id": d["id"], "disabled_by": None})
                elif entry["disabled_by"] and d["disabled_by"] is None and all(e in off for e in own):
                    self._device_update({"device_id": d["id"], "disabled_by": "config_entry"})
            return {"require_restart": False}
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

    def _supervisor(self, method: str, endpoint: str, data: Any) -> Any:
        parts = endpoint.strip("/").split("/")
        if (method, endpoint) == ("get", "/addons"):
            return {"addons": [{"slug": s, "name": a.get("name", s), "repository": a.get("repository", "core"), "state": a["state"]} for s, a in self.apps.items()]}
        if (method, endpoint) == ("get", "/store/repositories"):
            return copy.deepcopy(self.repositories)
        if method == "post" and endpoint == "/store/repositories":
            import hashlib
            slug = hashlib.sha1(data["repository"].lower().encode()).hexdigest()[:8]
            self.repositories.append({"slug": slug, "source": data["repository"]})
            return {}
        if method == "delete" and parts[:2] == ["store", "repositories"]:
            self.repositories = [r for r in self.repositories if r["slug"] != parts[2]]
            return {}
        if parts[:2] == ["store", "addons"]:
            slug = parts[2]
            offered = {"core", *(r["slug"] for r in self.repositories)}
            if slug not in self.store or self.store[slug].get("repository", "core") not in offered:
                raise HAError("supervisor/api", "unknown_error", "App does not exist")
            if len(parts) == 3:
                # The real store entry lacks the schema, options, ports, and boot rules.
                return {k: v for k, v in copy.deepcopy(self.store[slug]).items() if k in STORE_FIELDS}
            if parts[3] == "install":
                offer = self.store[slug]
                self.apps[slug] = {"name": offer.get("name", slug), "version": offer["version_latest"], "version_latest": offer["version_latest"],
                                   "options": copy.deepcopy(offer.get("options", {})), "schema": offer.get("schema", []), "state": "stopped",
                                   "boot": "auto", "boot_config": offer.get("boot_config", "auto"), "auto_update": False, "watchdog": False,
                                   "network": copy.deepcopy(offer.get("network")), "ingress_panel": None, "startup": offer.get("startup", "application"),
                                   "repository": offer.get("repository", "core")}
                return {}
            if parts[3] == "update":
                app = self.apps[slug]
                app["version"] = app["version_latest"]
                return {}
        if parts[0] == "addons":
            app = self.apps[parts[1]]
            action = parts[2]
            if action == "info":
                return copy.deepcopy(app)
            if action == "options" and len(parts) == 4:
                # The Supervisor's message quotes the whole options, as voluptuous does.
                return {"valid": "bad" not in data, "message": f"Invalid option 'bad'. Got {data!r}" if "bad" in data else "", "pwned": False}
            if action == "options":
                if "bad" in data.get("options", {}):
                    # The Supervisor's message quotes the whole options, as voluptuous does.
                    raise HAError("supervisor/api", "unknown_error", f"Invalid option 'bad'. Got {data['options']!r}")
                if "boot" in data and app.get("boot_config") == "manual_only":
                    raise HAError("supervisor/api", "unknown_error", "boot is manual_only")
                if "options" in data:
                    app["options"] = copy.deepcopy(data["options"])
                for key in ("boot", "auto_update", "watchdog", "ingress_panel", "network"):
                    if key in data:
                        app[key] = copy.deepcopy(data[key])
                return {}
            if action in ("start", "restart"):
                app["state"] = "started"
                app.setdefault("restarts", 0)
                app["restarts"] += action == "restart"
                return {}
            if action == "stop":
                app["state"] = "stopped"
                return {}
            if action == "uninstall":
                del self.apps[parts[1]]
                return {}
        raise NotImplementedError(f"{method} {endpoint}")

    def _hacs(self, command: str, fields: dict[str, Any]) -> Any:
        if self.hacs_repos is None:
            raise HAError(command, "unknown_command", "Unknown command.")
        if command == "hacs/info":
            return {"stage": "running", "disabled_reason": None, "version": "2.0.5"}
        if command == "hacs/repositories/list":
            return copy.deepcopy(self.hacs_repos)
        if command == "hacs/repositories/add":
            new_id = str(9000 + len(self.hacs_repos))
            self.hacs_repos.append({"id": new_id, "full_name": fields["repository"], "category": fields["category"], "installed": False,
                                    "installed_version": "", "custom": True})
            return {}
        repo = next(r for r in self.hacs_repos if r["id"] == fields["repository"])
        if command == "hacs/repository/download":
            repo.update({"installed": True, "installed_version": fields["version"]})
            return {}
        if command == "hacs/repository/remove":
            repo.update({"installed": False, "installed_version": ""})
            return {}
        if command == "hacs/repositories/remove":
            self.hacs_repos.remove(repo)
            return {}
        raise NotImplementedError(command)

    def _entity_update(self, command: str, fields: dict[str, Any]) -> Any:
        ent = next((e for e in self.entities if e["entity_id"] == fields["entity_id"]), None)
        if ent is None:
            raise HAError(command, "not_found", "Entity not found")
        device = next((d for d in self.devices if d["id"] == ent.get("device_id")), None)
        if fields.get("disabled_by", "unset") is None and device is not None and device["disabled_by"] is not None:
            raise HAError(command, "invalid_info", "Device is disabled")
        new = copy.deepcopy(ent)
        if "new_entity_id" in fields:
            if any(e["entity_id"] == fields["new_entity_id"] for e in self.entities):
                raise HAError(command, "invalid_info", "Entity with this ID is already registered")
            new["entity_id"] = fields["new_entity_id"]
        for f in ("name", "icon", "area_id", "labels", "aliases", "hidden_by", "disabled_by", "device_class"):
            if f in fields:
                new[f] = fields[f]
        if "categories" in fields:
            cats = dict(new.get("categories") or {})
            for scope, cid in fields["categories"].items():
                if cid is None:
                    cats.pop(scope, None)
                else:
                    cats[scope] = cid
            new["categories"] = cats
        if new["area_id"] and new["device_id"] and not new["name"] and not new["original_name"]:
            raise HAError(command, "invalid_info", "An entity without a name of its own cannot have an area of its own")
        ent.clear()
        ent.update(new)
        return {"entity_entry": copy.deepcopy(ent)}

    def _device_update(self, fields: dict[str, Any]) -> Any:
        dev = next(d for d in self.devices if d["id"] == fields["device_id"])
        for f in ("name_by_user", "area_id", "labels", "disabled_by"):
            if f in fields:
                dev[f] = fields[f]
        if "disabled_by" in fields:
            for e in self.entities:
                if e.get("device_id") == dev["id"]:
                    if fields["disabled_by"] and e["disabled_by"] is None:
                        e["disabled_by"] = "device"
                    elif not fields["disabled_by"] and e["disabled_by"] == "device":
                        e["disabled_by"] = None
        return copy.deepcopy(dev)

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
