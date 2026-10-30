"""Plan HACS repositories.

HACS keeps each repository it knows under its numeric GitHub id, and the
state keys repositories by `owner/repo`. The plan matches the two by the
repository's name, ignoring case.
"""

from __future__ import annotations

from typing import Any

from hastate.model import Change, Live

HACS = "hacs"
SELF = "hacs/integration"
"""HACS's own repository. The plan never removes it, and the apply updates it first."""

READY_STAGES = ("running", "background")
"""The HACS stages in which HACS takes commands. HACS is in `background` while it runs a scheduled task."""

DOWNLOAD_TIMEOUT = 600.0
"""The seconds a HACS download gets to finish. HACS answers only after the files are in place."""


def plan_hacs(want: dict[str, dict[str, Any]], live: Live, prune: bool) -> tuple[list[Change], list[str], list[str]]:
    changes: list[Change] = []
    problems: list[str] = []
    warnings: list[str] = []
    info = live.hacs_info
    if info is None:
        return changes, ["hacs: HACS is not installed, so the state cannot manage HACS repositories"], warnings
    if info.get("disabled_reason") or info.get("stage") not in READY_STAGES:
        return changes, [f"hacs: HACS is not running (stage {info.get('stage')!r}, disabled because {info.get('disabled_reason')!r})"], warnings

    by_name = {r["full_name"].lower(): r for r in live.hacs or []}
    for name, spec in want.items():
        address = f"{HACS}.{name}"
        repo = by_name.get(name.lower())
        if repo is not None and repo.get("category") != spec["category"]:
            problems.append(f"{address}: HACS lists the repository as {repo.get('category')!r}, not {spec['category']!r}")
            continue
        target = {"name": name, "category": spec["category"], "version": spec["version"], "id": repo and repo["id"]}
        if repo is None or not repo.get("installed"):
            change = Change("create", HACS, name, name, {"version": (None, spec["version"])}, target=target)
            if repo is None:
                change.notes.append(f"adds {name} to HACS as a custom {spec['category']} repository")
        elif repo.get("installed_version") != spec["version"]:
            change = Change("update", HACS, name, name, {"version": (repo.get("installed_version"), spec["version"])}, target=target)
        else:
            continue
        if spec["category"] == "integration":
            change.notes.append("HA must restart to load the new code")
        changes.append(change)

    for key, repo in by_name.items():
        if not repo.get("installed") or key in {n.lower() for n in want}:
            continue
        if prune and key != SELF:
            target = {"id": repo["id"], "custom": repo.get("custom", False), "category": repo.get("category")}
            change = Change("delete", HACS, repo["full_name"], repo["full_name"], target=target)
            change.notes.append(f"removes the {repo.get('category')} files from HA")
            changes.append(change)
        else:
            changes.append(Change("unmanaged", HACS, repo["full_name"], repo["full_name"]))
    return changes, problems, warnings


def restart_needed(changes: list[Change]) -> bool:
    """Report whether CHANGES change integration code, which HA loads only at start."""
    return any(c.collection == HACS and c.action in ("create", "update", "delete") and (c.target or {}).get("category") == "integration" for c in changes)


def self_update(changes: list[Change]) -> bool:
    """Report whether CHANGES download a new version of HACS itself, which runs only after HA restarts."""
    return any(c.collection == HACS and c.action in ("create", "update") and c.key.lower() == SELF for c in changes)


ADD_TIMEOUT = 30.0
"""The seconds HACS gets to add a custom repository. HACS sends no reply at all for a name it cannot parse."""


async def find_id(client: Any, name: str) -> str:
    repos = await client.call("hacs/repositories/list")
    ids = [r["id"] for r in repos if r["full_name"].lower() == name.lower()]
    if len(ids) != 1:
        raise RuntimeError(f"HACS lists {len(ids)} repositories named {name!r}")
    return ids[0]


async def install(client: Any, target: dict[str, Any]) -> None:
    """Download TARGET's version, adding the repository to HACS first when HACS does not know it.

    HACS reports a failed add only as an event, never as an error, so the
    apply lists the repositories again to check that the add worked.
    """
    repo_id = target.get("id")
    if repo_id is None:
        try:
            await client.call("hacs/repositories/add", repository=target["name"], category=target["category"], wait=ADD_TIMEOUT)
        except TimeoutError:
            raise RuntimeError(f"HACS did not answer the add of {target['name']!r} within {int(ADD_TIMEOUT)}s; check that the name is a GitHub `owner/repo`") from None
        repo_id = await find_id(client, target["name"])
    await client.call("hacs/repository/download", repository=repo_id, version=target["version"], wait=DOWNLOAD_TIMEOUT)
    repos = {r["id"]: r for r in await client.call("hacs/repositories/list")}
    got = repos.get(repo_id, {})
    if not got.get("installed") or got.get("installed_version") != target["version"]:
        raise RuntimeError(f"HACS reports {target['name']} at {got.get('installed_version')!r}, not {target['version']!r}")


async def remove(client: Any, target: dict[str, Any]) -> None:
    await client.call("hacs/repository/remove", repository=target["id"])
    if target.get("custom"):
        await client.call("hacs/repositories/remove", repository=target["id"])
