"""Read the live snapshot that a plan compares against."""

from __future__ import annotations

from typing import Any

from hastate import apps, hacs, http, settings
from hastate.client import Client, HAError
from hastate.model import CATEGORIES, CATEGORY_PREFIX, CATEGORY_SCOPES, REGISTRIES, Live
from hastate.plan import needs_states


async def read_live(client: Client, desired: dict[str, Any] | None = None) -> Live:
    """Read the snapshot that a plan of DESIRED needs, or every collection when DESIRED is None.

    The snapshot always holds every id-keyed registry, because a managed
    collection references unmanaged ones, such as areas that name floors. It
    holds the category scopes that a plan can touch: every scope in
    CATEGORY_SCOPES when the state manages categories, and every scope that
    the state or one of its entities names. It holds the entity and device
    registries when the state declares devices or entities, or prunes labels
    or categories, and the config entries when it declares integrations.
    hass:import passes None and reads everything.
    """
    full = desired is None
    desired = desired or {}
    live = Live(client.ha_version)
    for reg in REGISTRIES:
        live.registries[reg.collection] = await client.call(f"{reg.prefix}/list")

    scopes: list[str] = []
    if full or CATEGORIES in desired:
        scopes += CATEGORY_SCOPES
    scopes += list(desired.get(CATEGORIES, {}))
    scopes += [s for e in desired.get(settings.ENTITIES, {}).values() for s in e.get("categories") or {}]
    for scope in dict.fromkeys(scopes):
        live.categories[scope] = await client.call(f"{CATEGORY_PREFIX}/list", scope=scope)

    if not full and needs_states(desired):
        live.states = {s["entity_id"]: s for s in await client.call("get_states")}

    pruned = {"labels", CATEGORIES} & set(desired.get("prune", []))
    if full or pruned or settings.DEVICES in desired or settings.ENTITIES in desired:
        live.entities = await client.call("config/entity_registry/list")
        live.devices = await client.call("config/device_registry/list")

    # Only the extended entry carries aliases and the user's device class.
    wanted = desired.get(settings.ENTITIES, {})
    if full:
        ids = [e["entity_id"] for e in live.entities or []]
    else:
        # HA scopes a unique id to the domain and the platform, as the plan does.
        unique = {(e["entity_id"].split(".")[0], e["platform"], e["unique_id"]): e["entity_id"] for e in live.entities or []}
        ids = [
            unique.get((k.split(".")[0], s["match"]["platform"], s["match"]["unique_id"]), k) if "match" in s else k for k, s in wanted.items()
        ]
    if ids:
        details = await client.call("config/entity_registry/get_entries", entity_ids=ids)
        live.entity_details = {k: v for k, v in details.items() if v}

    if full or settings.INTEGRATIONS in desired:
        live.config_entries = await client.call("config_entries/get")

    if full or apps.APPS in desired or apps.REPOSITORIES in desired:
        await _read_apps(client, live, desired, full)
    if full or hacs.HACS in desired:
        await _read_hacs(client, live)
    if full or http.HTTP in desired:
        live.http = await client.call("http/config")
    return live


async def _read_apps(client: Client, live: Live, desired: dict[str, Any], full: bool) -> None:
    """Read the installed apps, the info of each app a plan touches, the store entry of each missing one, and the repositories.

    HA registers `supervisor/api` only under a Supervisor, so an unknown
    command leaves the apps unset, and the plan reports that HA runs
    without one.
    """
    try:
        installed = (await client.supervisor("get", "/addons"))["addons"]
    except HAError as err:
        if err.code != "unknown_command":
            raise
        return
    live.apps = installed
    slugs = {a["slug"] for a in installed}
    wanted = desired.get(apps.APPS, {})
    live.app_info = {}
    for slug in sorted(slugs if full else slugs & set(wanted)):
        live.app_info[slug] = await client.supervisor("get", f"/addons/{slug}/info")
    live.app_store = {}
    for slug in sorted(set(wanted) - slugs):
        try:
            live.app_store[slug] = await client.supervisor("get", f"/store/addons/{slug}")
        except HAError:
            continue
    repos = await client.supervisor("get", "/store/repositories")
    live.app_repositories = repos if isinstance(repos, list) else repos.get("repositories", [])


async def _read_hacs(client: Client, live: Live) -> None:
    """Read HACS's status and repositories. HACS registers its commands only when it runs, so an unknown command means no HACS."""
    try:
        live.hacs_info = await client.call("hacs/info")
    except HAError as err:
        if err.code != "unknown_command":
            raise
        return
    live.hacs = await client.call("hacs/repositories/list")
