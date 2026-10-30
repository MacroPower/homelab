"""Read the live snapshot that a plan compares against."""

from __future__ import annotations

from typing import Any

from hastate.client import Client
from hastate.plan import CATEGORIES, CATEGORY_PREFIX, CATEGORY_SCOPES, REGISTRIES, Live, needs_states


async def read_live(client: Client, desired: dict[str, Any] | None = None) -> Live:
    """Read the snapshot that a plan of DESIRED needs, or every collection when DESIRED is None.

    The snapshot always holds every id-keyed registry, because a managed
    collection references unmanaged ones, such as areas that name floors.
    When the state manages categories, or DESIRED is None, it holds every
    scope in CATEGORY_SCOPES and every scope the state names. It holds the
    entity and device registries when the state prunes labels or
    categories, so the plan can count what a delete changes.
    """
    live = Live(client.ha_version)
    for reg in REGISTRIES:
        live.registries[reg.collection] = await client.call(f"{reg.prefix}/list")
    if desired is None or CATEGORIES in desired:
        named = tuple(s for s in (desired or {}).get(CATEGORIES, {}) if s not in CATEGORY_SCOPES)
        for scope in CATEGORY_SCOPES + named:
            live.categories[scope] = await client.call(f"{CATEGORY_PREFIX}/list", scope=scope)
    if desired is not None and needs_states(desired):
        live.states = {s["entity_id"]: s for s in await client.call("get_states")}
    if desired is not None and {"labels", CATEGORIES} & set(desired.get("prune", [])):
        live.entities = await client.call("config/entity_registry/list")
        live.devices = await client.call("config/device_registry/list")
    return live
