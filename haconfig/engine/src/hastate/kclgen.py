"""Generate a KCL state file from a live snapshot, for hass:import."""

from __future__ import annotations

import json
import re
from typing import Any

from hastate import apps, hacs, http
from hastate.plan import AREAS, FLOORS, LABELS, Live, normalize

# Each KCL field name with the registry field it renders to. The order is the
# order the generated file lists the fields in.
KCL_FIELDS = {
    FLOORS.collection: {"name": "name", "level": "level", "icon": "icon", "aliases": "aliases"},
    AREAS.collection: {
        "name": "name",
        "floor": "floor_id",
        "icon": "icon",
        "aliases": "aliases",
        "labels": "labels",
        "picture": "picture",
        "temperatureEntity": "temperature_entity_id",
        "humidityEntity": "humidity_entity_id",
    },
    LABELS.collection: {"name": "name", "color": "color", "icon": "icon", "description": "description"},
}
REGISTRY = {reg.collection: reg for reg in (FLOORS, AREAS, LABELS)}

KEYWORDS = frozenset(
    "import as rule schema mixin protocol check for assert if elif else or and not in is lambda all any filter map "
    "True False None Undefined type".split()
)
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def kcl_string(s: str) -> str:
    """Return S as a KCL string literal. KCL reads `${` as interpolation, so the literal escapes it as `\\${`."""
    return json.dumps(s, ensure_ascii=False).replace("${", "\\${")


def kcl_key(k: str) -> str:
    return k if IDENTIFIER.fullmatch(k) and k not in KEYWORDS else kcl_string(k)


def kcl_value(v: Any) -> str:
    if v is None:
        return "None"
    if isinstance(v, dict):
        return "{" + ", ".join(f"{kcl_key(str(k))} = {kcl_value(x)}" for k, x in v.items()) + "}"
    if isinstance(v, bool):
        return "True" if v else "False"
    if isinstance(v, (int, float)):
        return json.dumps(v)
    if isinstance(v, str):
        return kcl_string(v)
    if isinstance(v, list):
        return "[" + ", ".join(kcl_value(x) for x in v) + "]"
    raise TypeError(f"cannot write {v!r} as KCL")


def comment(text: Any) -> str:
    """Return TEXT as one comment line.

    Device, app, and option names come from integrations and store
    repositories, so a line break in one would end the comment and turn the
    rest into KCL. The comment turns every control character and line
    separator into a space.
    """
    line = "".join(" " if ord(ch) < 0x20 or ch in "\x7f\x85\u2028\u2029" else ch for ch in str(text))
    return " ".join(line.split())


def slug(name: str) -> str:
    """Approximate HA's slugify for a generated map key."""
    return re.sub(r"[^a-z0-9]+", "_", name.casefold()).strip("_") or "category"


def _object(fields: dict[str, Any], indent: str) -> list[str]:
    return [f"{indent}{k} = {kcl_value(v)}" for k, v in fields.items()]


def _registry_block(collection: str, objects: list[dict[str, Any]], indent: str) -> list[str]:
    reg = REGISTRY[collection]
    if not objects:
        return [f"{indent}{collection} = {{}}"]
    lines = [f"{indent}{collection} = {{"]
    for obj in objects:
        fields = {}
        for kcl_name, ha_name in KCL_FIELDS[collection].items():
            v = normalize(obj.get(ha_name), ha_name in reg.set_fields)
            if v is not None and v != []:
                fields[kcl_name] = v
        lines.append(f"{indent}    {kcl_key(obj[reg.id_field])} = {{")
        lines += _object(fields, indent + "        ")
        lines.append(f"{indent}    }}")
    lines.append(f"{indent}}}")
    return lines


def unique_key(base: str, seen: set[str]) -> str:
    """Return BASE, or BASE with the first free `_N` suffix, and record it in SEEN."""
    key, n = base, 2
    while key in seen:
        key, n = f"{base}_{n}", n + 1
    seen.add(key)
    return key


def _block(name: str, entries: list[tuple[str, list[str], dict[str, Any]]], indent: str) -> list[str]:
    """Write NAME as a map of ENTRIES, each a key, its comment lines, and its fields.

    A field named `#x` holds a comment line that the block writes directly
    above field `x`, such as a Renovate comment above `version`.
    """
    if not entries:
        return [f"{indent}{name} = {{}}"]
    lines = [f"{indent}{name} = {{"]
    for key, comments, fields in entries:
        lines += [f"{indent}    # {comment(c)}" for c in comments]
        lines.append(f"{indent}    {kcl_key(key)} = {{")
        for k, v in fields.items():
            if k.startswith("#"):
                continue
            if f"#{k}" in fields:
                lines.append(f"{indent}        # {comment(fields[f'#{k}'])}")
            if isinstance(v, dict):
                lines.append(f"{indent}        {k} = {{" + ", ".join(f"{kcl_key(a)} = {kcl_value(b)}" for a, b in v.items()) + "}")
            else:
                lines.append(f"{indent}        {k} = {kcl_value(v)}")
        lines.append(f"{indent}    }}")
    lines.append(f"{indent}}}")
    return lines


def _categories(live: Live) -> list[str]:
    scopes = {scope: entries for scope, entries in live.categories.items() if entries}
    if not scopes:
        return ["    categories = {}"]
    lines = ["    categories = {"]
    for scope, entries in scopes.items():
        seen: set[str] = set()
        rows = [(unique_key(slug(e["name"]), seen), [], {k: e[k] for k in ("name", "icon") if e.get(k)}) for e in entries]
        lines += _block(kcl_key(scope), rows, "        ")
    lines.append("    }")
    return lines


def _devices(live: Live) -> list[tuple[str, list[str], dict[str, Any]]]:
    """Return each device that carries a setting you made, with only those settings."""
    rows = []
    seen: set[str] = set()
    for d in live.devices or []:
        fields: dict[str, Any] = {"match": {"id": d["id"]}}
        if d.get("name_by_user"):
            fields["name"] = d["name_by_user"]
        if d.get("area_id"):
            fields["area"] = d["area_id"]
        if d.get("labels"):
            fields["labels"] = sorted(d["labels"])
        if d.get("disabled_by") == "user":
            fields["disabled"] = True
        if len(fields) == 1:
            continue
        about = " ".join(str(x) for x in (d.get("manufacturer"), d.get("model")) if x)
        # Some integrations name a device after the account's email address,
        # which the public repo must not hold.
        names = [n for n in (d.get("name_by_user"), d.get("name")) if n and "@" not in n]
        label = names[0] if names else about or "device"
        title = d.get("name") if d.get("name") and "@" not in d["name"] else label
        rows.append((unique_key(slug(label), seen), [f"{title}{f' ({about})' if about and about != title else ''}"], fields))
    return rows


def _entities(live: Live) -> list[tuple[str, list[str], dict[str, Any]]]:
    """Return each entity that carries a setting you made, with only those settings."""
    details = live.entity_details or {}
    names = {scope: {c["category_id"]: c["name"] for c in cats} for scope, cats in live.categories.items()}
    rows = []
    for e in live.entities or []:
        extended = details.get(e["entity_id"], {})
        fields: dict[str, Any] = {}
        for kcl_name, ha_name in (("name", "name"), ("icon", "icon"), ("area", "area_id")):
            if e.get(ha_name):
                fields[kcl_name] = e[ha_name]
        if e.get("labels"):
            fields["labels"] = sorted(e["labels"])
        aliases = [a for a in extended.get("aliases") or [] if a is not None]
        if aliases:
            fields["aliases"] = aliases
        if e.get("hidden_by") == "user":
            fields["hidden"] = True
        if e.get("disabled_by") == "user":
            fields["disabled"] = True
        if extended.get("device_class"):
            fields["deviceClass"] = extended["device_class"]
        cats = {scope: names.get(scope, {}).get(cid) for scope, cid in (e.get("categories") or {}).items()}
        if cats and all(cats.values()):
            fields["categories"] = cats
        if fields:
            rows.append((e["entity_id"], [], fields))
    return rows


def _integrations(live: Live) -> list[tuple[str, list[str], dict[str, Any]]]:
    entries = [e for e in live.config_entries or [] if e.get("source") != "ignore"]
    domains = [e["domain"] for e in entries]
    rows = []
    seen: set[str] = set()
    for e in entries:
        # Some integrations title an entry with the account's email address,
        # which the public repo must not hold. The entry id alone matches it.
        private = "@" in (e.get("title") or "")
        if domains.count(e["domain"]) == 1:
            base = e["domain"]
        else:
            base = e["domain"] if private else f"{e['domain']}_{slug(e['title'])}"
        fields: dict[str, Any] = {"domain": e["domain"], "entryId": e["entry_id"]}
        if not private:
            fields["title"] = e["title"]
        if e.get("disabled_by") == "user":
            fields["disabled"] = True
        if e.get("pref_disable_new_entities"):
            fields["disableNewEntities"] = True
        if e.get("pref_disable_polling"):
            fields["disablePolling"] = True
        rows.append((unique_key(slug(base), seen), [], fields))
    return rows


RENOVATE = "renovate: datasource={datasource} depName={dep}"
"""The comment that the Renovate regex manager in .github/renovate.json5 matches on the line above a version."""

APP_SOURCES = {"core": "home-assistant/apps/master", "a0d7b954": "hassio-addons/repository/master"}
"""The `<owner>/<repo>/<branch>` of each store repository whose app versions the `ha-app` Renovate datasource reads."""

APP_FOLDERS = {
    "core_silabs_multiprotocol": "silabs-multiprotocol",
    "core_speech-to-phrase": "speech_to_phrase",
    "a0d7b954_nodered": "node-red",
    "a0d7b954_zwavejs2mqtt": "zwave-js-ui",
    "a0d7b954_sonweb": "tasmoadmin",
    "a0d7b954_jupyterlablite": "jupyterlab",
}
"""The apps whose folder in their store repository differs from their slug without the repository prefix."""


def _apps(live: Live) -> list[tuple[str, list[str], dict[str, Any]]]:
    """Return each installed app with its settings and the options that cannot hold a secret.

    The repo is public, so the import fails closed. It writes an option only
    when its schema type cannot hold free text, such as a boolean or a
    select. The app's comment names every other option, so you can add it
    by hand, with tags.secret() for a secret.
    """
    rows = []
    for app in live.apps or []:
        info = (live.app_info or {}).get(app["slug"], {})
        safe = apps.importable_keys(info)
        fields: dict[str, Any] = {}
        if not info.get("auto_update") and info.get("version"):
            fields["version"] = info["version"]
            source = APP_SOURCES.get(app.get("repository") or "")
            if source:
                folder = APP_FOLDERS.get(app["slug"]) or app["slug"].removeprefix(f"{app['repository']}_")
                fields["#version"] = RENOVATE.format(datasource="custom.ha-app", dep=app["slug"]) + f" packageName={source}/{folder}"
        live_options = info.get("options") or {}
        options = {k: v for k, v in live_options.items() if k in safe}
        if options:
            fields["options"] = options
        if info.get("boot") and info.get("boot_config") != "manual_only":
            fields["boot"] = info["boot"]
        fields["autoUpdate"] = bool(info.get("auto_update"))
        # The Supervisor ignores a watchdog on an app that runs once at
        # startup, and such an app stops on its own after each run.
        if info.get("startup") != "once":
            fields["watchdog"] = bool(info.get("watchdog"))
        if info.get("network"):
            fields["network"] = info["network"]
        if info.get("ingress_panel") is not None:
            fields["ingressPanel"] = info["ingress_panel"]
        if info.get("startup") != "once":
            fields["started"] = info.get("state") in ("started", "startup")
        comments = [f"{app.get('name') or app['slug']}"]
        skipped = sorted(k for k in live_options if k not in safe)
        if skipped:
            comments.append(f"Options not imported, because they can hold secrets or free text: {', '.join(skipped)}")
        rows.append((app["slug"], comments, fields))
    return rows


COMMIT = re.compile(r"(?=[0-9]*[a-f])[0-9a-f]{7,40}")
"""A commit hash. HACS reports the installed commit of a repository without releases, often in its 7-character short form.

A release tag made only of digits, such as `20240115`, is not a commit, so a
commit must hold a letter. A short commit made only of digits gets the
Renovate comment, and Renovate then finds no release for it.
"""


def _hacs(live: Live) -> list[str]:
    """Return the installed HACS repositories, each with a Renovate comment above a release version."""
    repos = sorted((r for r in live.hacs or [] if r.get("installed")), key=lambda r: r["full_name"].lower())
    if not repos:
        return ["    hacs = {}"]
    lines = ["    hacs = {"]
    for repo in repos:
        version = repo.get("installed_version") or ""
        lines += [f"        {kcl_key(repo['full_name'])} = {{", f"            category = {kcl_value(repo['category'])}"]
        if not COMMIT.fullmatch(version):
            lines.append("            # " + comment(RENOVATE.format(datasource="github-releases", dep=repo["full_name"])))
        elif len(version) < 40:
            lines.append("            # HACS reports a short commit; replace it with the full 40-character commit hash")
        lines += [f"            version = {kcl_value(version)}", "        }"]
    lines.append("    }")
    return lines


def _http(live: Live) -> list[str]:
    """Return the HTTP config, with only the settings that differ from HA's defaults, because an unset field takes the default."""
    default = http.config_of((live.http or {}).get("default"))
    stable = http.config_of((live.http or {}).get("stable"))
    names = {
        "server_port": "serverPort", "server_host": "serverHost", "ssl_certificate": "sslCertificate", "ssl_key": "sslKey",
        "ssl_peer_certificate": "sslPeerCertificate", "ssl_profile": "sslProfile", "cors_allowed_origins": "corsAllowedOrigins",
        "use_x_forwarded_for": "useXForwardedFor", "trusted_proxies": "trustedProxies", "ip_ban_enabled": "ipBanEnabled",
        "login_attempts_threshold": "loginAttemptsThreshold", "use_x_frame_options": "useXFrameOptions",
    }
    fields = {names[k]: v for k, v in stable.items() if k in names and default.get(k) != v}
    if not fields:
        return ["    http = {}"]
    return ["    http = {", *[f"        {k} = {kcl_value(v)}" for k, v in fields.items()], "    }"]


def generate(live: Live, url: str, variable: str = "hass_state") -> str:
    """Return a KCL file that declares VARIABLE as the State that LIVE holds.

    The file sets every registry and every category scope, and leaves out
    each field that is empty in HA, because the state treats an unset field
    as empty. It lists each device and entity that carries a setting you
    made, with only those settings, and every integration. A plan of the
    generated state against LIVE is therefore empty.
    """
    lines = [
        f"# Generated by `task hass:import` from {url} (Home Assistant {live.ha_version}).",
        "# Edit it freely. Git owns this state now, and `task hass:apply` makes HA match it.",
        "import haconfig.models.frontend.state as hstate",
        "",
        f"{variable} = hstate.State {{",
    ]
    for collection in (FLOORS.collection, AREAS.collection, LABELS.collection):
        lines += _registry_block(collection, live.registries.get(collection, []), "    ")
    lines += _categories(live)
    if live.devices is not None:
        lines += _block("devices", _devices(live), "    ")
    if live.entities is not None:
        lines += _block("entities", _entities(live), "    ")
    if live.config_entries is not None:
        lines += _block("integrations", _integrations(live), "    ")
    if live.apps is not None:
        lines += _block("apps", _apps(live), "    ")
        custom = [r["source"] for r in live.app_repositories or [] if r.get("slug") not in apps.BUILTIN_REPOSITORIES]
        # The Supervisor keys a repository by its whole URL, credentials
        # included, so the import cannot strip them and skips the repository.
        private = sorted(apps.redact_url(u) for u in custom if apps.has_credentials(u))
        if private:
            lines.append(f"    # Repositories not imported, because their URLs hold credentials: {comment(', '.join(private))}")
        lines.append(f"    appRepositories = {kcl_value(sorted(u for u in custom if not apps.has_credentials(u)))}")
    if live.hacs_info is not None:
        lines += _hacs(live)
    if live.http is not None:
        lines += _http(live)
    lines.append("}")
    return "\n".join(lines) + "\n"
