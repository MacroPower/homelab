"""Plan Supervisor apps and app repositories.

The engine reaches the Supervisor through HA's `supervisor/api` WebSocket
command, which forwards any Supervisor endpoint for an admin user, so it needs
the same token as the registries and no SSH.
"""

from __future__ import annotations

import hashlib
import re
from typing import Any
from urllib.parse import urlsplit, urlunsplit

from hastate.client import HAError
from hastate.model import Change, Live

APPS = "apps"
REPOSITORIES = "app_repositories"

BUILTIN_REPOSITORIES = frozenset({"core", "local", "a0d7b954", "5c53de3b", "d5369777"})
"""The repository slugs the Supervisor always carries and never removes."""

SETTINGS = {"boot": "boot", "auto_update": "auto_update", "watchdog": "watchdog", "ingress_panel": "ingress_panel"}
"""The state fields that the Supervisor's options endpoint sets, each with its body key."""

SENSITIVE_NAME = re.compile(r"pass|secret|token|key|psk|credential|auth|email|user|login|cert", re.IGNORECASE)
"""Option names whose values the plan never prints, besides the schema's password fields.

The repo is public, so the pattern also covers personal data such as email
addresses and user names.
"""

FREEFORM_NAME = re.compile(r"env|command|args|script|extra", re.IGNORECASE)
"""Option names that hold free-form settings, such as `env_vars` lists of name and value pairs, which can carry any secret."""

SAFE_TYPES = frozenset({"boolean", "integer", "float", "select"})
"""The schema types whose values cannot carry a secret. hass:import writes only options of these types."""

REDACTED = "(sensitive)"

INSTALL_TIMEOUT = 1800.0
"""The seconds an install or an update gets to finish. Image pulls on a Pi take minutes."""


def _labelled_secret(value: Any) -> bool:
    """Report whether VALUE holds a field whose name, or whose `name` or `key` label, looks like a credential."""
    if isinstance(value, dict):
        labels = [str(value.get(k, "")) for k in ("name", "key")]
        if any(SENSITIVE_NAME.search(label) for label in labels if label):
            return True
        return any(SENSITIVE_NAME.search(str(k)) or _labelled_secret(v) for k, v in value.items())
    if isinstance(value, list):
        return any(_labelled_secret(v) for v in value)
    return False


def sensitive_keys(info: dict[str, Any]) -> set[str]:
    """Return the top-level option names whose values the plan must hide.

    The schema marks password fields with the `password` format, and nested
    schema fields can hold one. Many apps keep keys and tokens in plain
    string fields, such as Z-Wave's network keys, or in `env_vars` lists of
    name and value pairs, so a credential-like name, a credential-like
    `name` label, or a free-form option name also counts.
    """

    def has_password(node: dict[str, Any]) -> bool:
        if node.get("format") == "password" or SENSITIVE_NAME.search(str(node.get("name", ""))):
            return True
        return any(has_password(child) for child in node.get("schema") or [] if isinstance(child, dict))

    keys = {n["name"] for n in info.get("schema") or [] if isinstance(n, dict) and has_password(n)}
    keys |= {k for k, v in (info.get("options") or {}).items() if SENSITIVE_NAME.search(k) or FREEFORM_NAME.search(k) or _labelled_secret(v)}
    return keys


def _strings(value: Any) -> list[str]:
    """Return every string in VALUE, a nested option value."""
    if isinstance(value, dict):
        return [s for v in value.values() for s in _strings(v)]
    if isinstance(value, list):
        return [s for v in value for s in _strings(v)]
    return [value] if isinstance(value, str) else []


def _holds_none(value: Any) -> bool:
    if isinstance(value, dict):
        return any(_holds_none(v) for v in value.values())
    if isinstance(value, list):
        return any(_holds_none(v) for v in value)
    return value is None


def importable_keys(info: dict[str, Any]) -> set[str]:
    """Return the top-level options that hass:import can safely write to the public repo.

    The import fails closed. It writes an option only when its schema type
    cannot hold free text, such as a boolean or a select, and when nothing
    about it looks like a credential. It skips an option without a value,
    because the state rejects None. Every other option stays for you to add
    by hand, with tags.secret() for a secret.
    """

    def safe(node: dict[str, Any]) -> bool:
        if node.get("type") == "schema":
            return all(safe(child) for child in node.get("schema") or [] if isinstance(child, dict))
        return node.get("type") in SAFE_TYPES

    schema = {n.get("name"): n for n in info.get("schema") or [] if isinstance(n, dict)}
    hidden = sensitive_keys(info)
    options = info.get("options") or {}
    return {
        k for k, v in options.items()
        if k in schema and k not in hidden and safe(schema[k]) and not _holds_none(v)
    }


def hidden_options(desired: dict[str, Any], current: dict[str, Any]) -> set[str]:
    """Return the declared options whose values the plan hides, whatever their names.

    An option that moves to a secret held a secret before, and a URL can
    carry a user name and a password.
    """
    keys = set()
    for k, v in desired.items():
        values = _strings(v) + _strings(current.get(k))
        if any(s.startswith("!secret ") or (s.count("://") and has_credentials(s)) for s in values):
            keys.add(k)
    return keys


def coerce(schema: list[dict[str, Any]] | None, options: dict[str, Any]) -> dict[str, Any]:
    """Return OPTIONS with each value in the type the Supervisor stores for it under SCHEMA, its UI schema.

    The Supervisor turns a select or a pattern value into a string, and an
    integer or a float value into a number, so `460800` for a select of
    baud rates comes back as `"460800"`. The plan compares the stored form.
    """
    nodes = {n.get("name"): n for n in schema or [] if isinstance(n, dict)}
    return {k: _coerce(nodes.get(k), v) for k, v in options.items()}


def _coerce(node: dict[str, Any] | None, value: Any) -> Any:
    if node is None or value is None:
        return value
    if node.get("multiple") and isinstance(value, list):
        return [_coerce({**node, "multiple": False}, v) for v in value]
    if node.get("type") == "schema":
        return coerce(node.get("schema"), value) if isinstance(value, dict) else value
    if isinstance(value, bool) or (isinstance(value, str) and value.startswith("!secret ")):
        return value
    kind = node.get("type")
    try:
        if kind in ("select", "string") and isinstance(value, (int, float)):
            return str(value)
        if kind == "integer" and isinstance(value, (str, float)) and float(value).is_integer():
            return int(float(value))
        if kind == "float" and isinstance(value, (int, str)):
            return float(value)
    except ValueError:
        pass
    return value


def scrub(message: str, options: dict[str, Any]) -> str:
    """Return a Supervisor error MESSAGE without the option values it quotes.

    The Supervisor's validation messages end with `. Got <value>`, and that
    value can hold every option, secrets included. The scrub cuts that
    suffix from each line and hides any option string that still appears.
    """
    lines = [line.split(". Got ")[0] for line in str(message).splitlines()]
    text = "\n".join(lines)
    for s in sorted((s for s in _strings(options) if len(s) >= 3), key=len, reverse=True):
        text = text.replace(s, REDACTED)
    return text


def redact_url(url: str) -> str:
    """Return URL without the user name and password in its authority."""
    parts = urlsplit(url)
    if not (parts.username or parts.password):
        return url
    host = parts.hostname or ""
    if parts.port:
        host = f"{host}:{parts.port}"
    return urlunsplit((parts.scheme, f"{REDACTED}@{host}", parts.path, parts.query, parts.fragment))


def has_credentials(url: str) -> bool:
    parts = urlsplit(url)
    return bool(parts.username or parts.password)


def check_app(spec: dict[str, Any], info: dict[str, Any]) -> list[str]:
    """Return each reason the Supervisor rejects or silently drops a field of SPEC for the app INFO describes.

    The plan runs these checks for an installed app, and the apply runs them
    again after an install, because the store entry of an app that nobody
    installed yet lacks its schema, ports, and boot rules.
    """
    problems: list[str] = []
    schema = {n.get("name"): n for n in info.get("schema") or [] if isinstance(n, dict)}
    known = set(schema) | set(info.get("options") or {})
    for key, value in (spec.get("options") or {}).items():
        if known and key not in known:
            problems.append(f"the app has no option {key!r}; the Supervisor drops unknown options")
        if value is None:
            problems.append(f"options.{key} is None; the Supervisor restores an option's default, so set the default value instead")
    if "boot" in spec and info.get("boot_config") == "manual_only":
        problems.append("the app's boot is manual_only, so the state cannot set boot")
    if spec.get("watchdog") and info.get("startup") == "once":
        problems.append("the app runs once at startup, and the Supervisor ignores a watchdog on such an app")
    offered = set(info.get("network") or {})
    for port in spec.get("network") or {}:
        if port not in offered:
            problems.append(f"the app has no port {port!r}; the Supervisor drops unknown ports")
    return problems


def repository_of(slug: str) -> str:
    """Return the repository slug of an app slug, the part before the first underscore, such as `a0d7b954`."""
    return slug.split("_", 1)[0]


def plan_apps(
    want: dict[str, dict[str, Any]], live: Live, prune: bool, new_repositories: set[str]
) -> tuple[list[Change], list[str], list[str]]:
    """Plan each declared app, and each installed app that the state lacks.

    NEW_REPOSITORIES holds the slugs of the repositories that the same plan
    adds. An app from one of them is not in the store yet, so the plan
    installs it and the apply checks its pin after it adds the repository.
    """
    if live.apps is None:
        return [], [f"{APPS}: {NO_SUPERVISOR}"], []
    installed = {a["slug"]: a for a in live.apps or []}
    infos = live.app_info or {}
    store = live.app_store or {}
    changes: list[Change] = []
    problems: list[str] = []
    warnings: list[str] = []

    for slug, spec in want.items():
        address = f"{APPS}.{slug}"
        named = {k for k in spec.get("options") or {} if SENSITIVE_NAME.search(k) or FREEFORM_NAME.search(k)}
        named |= hidden_options(spec.get("options") or {}, (infos.get(slug) or {}).get("options") or {})
        if slug not in installed:
            offer = store.get(slug)
            if offer is None and repository_of(slug) not in new_repositories:
                problems.append(f"{address}: the Supervisor store has no app {slug!r}; add its repository to appRepositories")
                continue
            pin = spec.get("version")
            if offer is not None and pin and offer.get("version_latest") != pin:
                problems.append(f"{address}: the store offers {offer.get('version_latest')!r}, not the pinned {pin!r}, and the Supervisor installs only the latest")
                continue
            problems += [f"{address}: {p}" for p in check_app({"options": {k: v for k, v in (spec.get("options") or {}).items() if v is None}}, {})]
            latest = offer.get("version_latest") if offer else "(the store's latest, once the repository is added)"
            diff: dict[str, tuple[Any, Any]] = {"version": (None, latest)}
            diff |= _settings_diff(spec, {})
            if "started" in spec:
                diff["state"] = (None, "started" if spec["started"] else "stopped")
            change = Change("create", APPS, slug, (offer or {}).get("name") or slug, diff, target=spec)
            change.sensitive = {f"options.{k}" for k in named}
            change.notes.append("the apply checks the options, ports, and boot rules after the install, because the store does not list them")
            changes.append(change)
            continue
        info = infos[slug]
        problems += [f"{address}: {p}" for p in check_app(spec, info)]
        diff = _settings_diff(spec, info)
        pin = spec.get("version")
        if pin and pin != info.get("version"):
            if info.get("version_latest") == pin:
                diff["version"] = (info.get("version"), pin)
            else:
                warnings.append(
                    f"{address}: pinned to {pin!r}, but {info.get('version')!r} runs and the store offers {info.get('version_latest')!r}; "
                    "the Supervisor cannot install another version"
                )
        if "started" in spec:
            running = info.get("state") in ("started", "startup")
            if spec["started"] != running:
                diff["state"] = (info.get("state"), "started" if spec["started"] else "stopped")
        if diff:
            change = Change("update", APPS, slug, info.get("name") or slug, diff, target=spec)
            change.sensitive = {f"options.{k}" for k in sensitive_keys(info) | named}
            changes.append(change)

    for slug, app in installed.items():
        if slug in want:
            continue
        action = "delete" if prune else "unmanaged"
        changes.append(Change(action, APPS, slug, app.get("name") or slug, target=slug))
        if prune:
            changes[-1].notes.append("uninstalls the app and deletes its data; only its folder under /addon_configs stays")
    return changes, problems, warnings


def _settings_diff(spec: dict[str, Any], info: dict[str, Any]) -> dict[str, tuple[Any, Any]]:
    """Return the changed options, settings, and ports of SPEC against INFO, one diff entry per key."""
    diff: dict[str, tuple[Any, Any]] = {}
    live_options = info.get("options") or {}
    for key, value in coerce(info.get("schema"), spec.get("options") or {}).items():
        if live_options.get(key) != value:
            diff[f"options.{key}"] = (live_options.get(key), value)
    for field, info_key in SETTINGS.items():
        if field in spec and info.get(info_key) != spec[field]:
            diff[field] = (info.get(info_key), spec[field])
    ports = info.get("network") or {}
    for port, host in (spec.get("network") or {}).items():
        if ports.get(port) != host:
            diff[f"network.{port}"] = (ports.get(port), host)
    return diff


def repository_slug(url: str) -> str | None:
    """Return the Supervisor's slug for a repository URL, or None for a URL it maps to a built-in repository."""
    if url.rstrip("/") in ("https://github.com/home-assistant/apps", "https://github.com/home-assistant/addons"):
        return None
    return hashlib.sha1(url.lower().encode()).hexdigest()[:8]


def new_repository_slugs(want: list[str], live: Live) -> set[str]:
    """Return the slugs of the declared repositories that the store lacks."""
    current = {r["slug"] for r in live.app_repositories or []}
    return {s for s in (repository_slug(u) for u in want) if s and s not in current}


def plan_repositories(want: list[str], live: Live, prune: bool, app_changes: list[Change]) -> tuple[list[Change], list[str]]:
    """Plan the store repositories.

    APP_CHANGES holds the app changes of the same plan. An app it uninstalls
    no longer keeps its repository, and an app it installs needs its own.
    """
    if live.apps is None:
        return [], [f"{REPOSITORIES}: {NO_SUPERVISOR}"]
    current = {r["slug"]: r for r in live.app_repositories or []}
    changes: list[Change] = []
    problems: list[str] = []
    declared: set[str] = set()
    for url in want:
        slug = repository_slug(url)
        if slug is None:
            continue
        declared.add(slug)
        if slug not in current:
            change = Change("create", REPOSITORIES, slug, redact_url(url), {"source": (None, redact_url(url))}, target=url)
            changes.append(change)
    uninstalled = {c.key for c in app_changes if c.action == "delete"}
    used = {a.get("repository") for a in live.apps or [] if a["slug"] not in uninstalled}
    used |= {repository_of(c.key) for c in app_changes if c.action == "create"}
    for slug, repo in current.items():
        if slug in declared or slug in BUILTIN_REPOSITORIES:
            continue
        name = redact_url(repo.get("source") or slug)
        if prune:
            if slug in used:
                problems.append(f"{REPOSITORIES}.{slug}: cannot remove {name!r}, because an app that stays installed comes from it")
                continue
            changes.append(Change("delete", REPOSITORIES, slug, name, target=slug))
        else:
            changes.append(Change("unmanaged", REPOSITORIES, slug, name))
    return changes, problems


NO_SUPERVISOR = "HA runs without a Supervisor, so the state cannot manage apps or app repositories"


def merged_options(current: dict[str, Any], desired: dict[str, Any]) -> dict[str, Any]:
    """Return CURRENT with each key of DESIRED set."""
    return {**current, **desired}


async def _call(client: Any, method: str, endpoint: str, data: Any = None, timeout: float = 60.0, options: dict[str, Any] | None = None) -> Any:
    """Call the Supervisor, and scrub the option values out of any error it reports."""
    try:
        return await client.supervisor(method, endpoint, data, timeout=timeout)
    except HAError as err:
        raise RuntimeError(f"{method.upper()} {endpoint}: {scrub(err.message, options or {})}") from None


async def add_repository(client: Any, url: str) -> None:
    """Add the store repository at URL. An error names the URL without the credentials it might hold."""
    try:
        await client.supervisor("post", "/store/repositories", {"repository": url})
    except HAError as err:
        raise RuntimeError(f"POST /store/repositories: {err.message.replace(url, redact_url(url))}") from None


async def install(client: Any, slug: str, pin: str | None) -> None:
    """Install the app, after checking that the store offers the pinned version."""
    try:
        offer = await client.supervisor("get", f"/store/addons/{slug}")
    except HAError:
        raise RuntimeError(f"the Supervisor store has no app {slug!r}") from None
    if pin and offer.get("version_latest") != pin:
        raise RuntimeError(f"the store offers {offer.get('version_latest')!r}, not the pinned {pin!r}")
    await _call(client, "post", f"/store/addons/{slug}/install", {"background": False}, timeout=INSTALL_TIMEOUT)


async def update(client: Any, slug: str) -> None:
    await _call(client, "post", f"/store/addons/{slug}/update", {"backup": False, "background": False}, timeout=INSTALL_TIMEOUT)


async def configure(client: Any, slug: str, spec: dict[str, Any]) -> bool:
    """Write the options, settings, and ports that SPEC sets, and return whether the app must restart.

    The Supervisor replaces an app's options whole, so the apply merges the
    declared keys into the current options. It checks the fields against the
    installed app first. The Supervisor reloads secrets.yaml and validates
    the options before it stores them, so a bad option fails the step and
    changes nothing. The app must restart only when the options or ports
    that the Supervisor reports afterwards differ.
    """
    info = await _call(client, "get", f"/addons/{slug}/info")
    problems = check_app(spec, info)
    if problems:
        raise RuntimeError("; ".join(problems))
    current = info.get("options") or {}
    body: dict[str, Any] = {}
    if "options" in spec:
        options = merged_options(current, coerce(info.get("schema"), spec["options"]))
        if options != current:
            body["options"] = options
    for field, key in SETTINGS.items():
        if field in spec and info.get(key) != spec[field]:
            body[key] = spec[field]
    if "network" in spec:
        ports = {**(info.get("network") or {}), **spec["network"]}
        if ports != (info.get("network") or {}):
            body["network"] = ports
    if not body:
        return False
    await _call(client, "post", f"/addons/{slug}/options", body, options=body.get("options"))
    after = await _call(client, "get", f"/addons/{slug}/info")
    return (after.get("options"), after.get("network")) != (current, info.get("network"))


async def set_state(client: Any, slug: str, started: bool | None, restart: bool) -> None:
    """Start or stop the app as STARTED asks, or restart a running app when RESTART is set, so new options and ports take effect."""
    info = await _call(client, "get", f"/addons/{slug}/info")
    running = info.get("state") in ("started", "startup")
    if started is True and not running:
        await _call(client, "post", f"/addons/{slug}/start", timeout=300)
    elif started is False and running:
        await _call(client, "post", f"/addons/{slug}/stop", timeout=300)
    elif restart and running:
        await _call(client, "post", f"/addons/{slug}/restart", timeout=300)


async def uninstall(client: Any, slug: str) -> None:
    await _call(client, "post", f"/addons/{slug}/uninstall", {"remove_config": False}, timeout=300)
