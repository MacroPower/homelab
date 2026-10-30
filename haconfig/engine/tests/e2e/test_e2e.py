"""End-to-end tests against a fresh Home Assistant container.

The module starts HASS_IMAGE in Docker, onboards an admin user through the
onboarding API, and runs the engine against it. The tests share one instance
and run in file order, each one building on the state the last one left.
Onboarding creates the areas living_room, kitchen, and bedroom, and the
demo integration provides real devices, entities, and a config entry.
"""

from __future__ import annotations

import asyncio
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from collections.abc import Iterator
from pathlib import Path

import pytest

from hastate.apply import ApplyError, apply
from hastate.client import Client
from hastate.kclgen import generate
from hastate.live import read_live
from hastate.plan import Live, plan

sys.path.insert(0, str(Path(__file__).resolve().parent))
from relay import Relay  # noqa: E402

pytestmark = pytest.mark.e2e

IMAGE = os.environ.get("HASS_IMAGE", "ghcr.io/home-assistant/home-assistant:2026.10.4")
CONFIG = """\
homeassistant:
  name: haconfig e2e
api:
config:
demo:
onboarding:
websocket_api:
"""


def http(method: str, url: str, data: dict | None = None, form: bool = False) -> dict:
    body, headers = None, {}
    if data is not None:
        if form:
            body, headers["Content-Type"] = urllib.parse.urlencode(data).encode(), "application/x-www-form-urlencoded"
        else:
            body, headers["Content-Type"] = json.dumps(data).encode(), "application/json"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read() or b"null")


@pytest.fixture(scope="module")
def ha() -> Iterator[tuple[str, str]]:
    """Start HA, onboard a user, and yield the base URL and an access token."""
    name = f"haconfig-e2e-{uuid.uuid4().hex[:8]}"
    # docker cp copies the config into the container's own /config, so no host
    # file becomes owned by the container's root user.
    subprocess.run(["docker", "create", "--name", name, IMAGE], check=True, capture_output=True)
    relay = None
    try:
        config_dir = Path(os.environ.get("TMPDIR", "/tmp")) / name
        config_dir.mkdir()
        (config_dir / "configuration.yaml").write_text(CONFIG)
        subprocess.run(["docker", "cp", f"{config_dir}/.", f"{name}:/config"], check=True, capture_output=True)
        subprocess.run(["docker", "start", name], check=True, capture_output=True)
        relay = Relay(name, 8123)
        base = f"http://127.0.0.1:{relay.port}"
        deadline = time.monotonic() + 240
        while True:
            try:
                http("GET", f"{base}/api/onboarding")
                break
            except (urllib.error.URLError, ConnectionError, TimeoutError) as err:
                if time.monotonic() > deadline:
                    logs = subprocess.run(["docker", "logs", "--tail", "50", name], capture_output=True, text=True)
                    pytest.fail(f"HA did not answer within 240s ({err}):\n{logs.stdout}{logs.stderr}")
                time.sleep(2)
        client_id = f"{base}/"
        code = http("POST", f"{base}/api/onboarding/users", {"client_id": client_id, "name": "E2E", "username": "e2e", "password": "e2e-password", "language": "en"})["auth_code"]
        token = http("POST", f"{base}/auth/token", {"grant_type": "authorization_code", "code": code, "client_id": client_id}, form=True)["access_token"]
        yield base, token
    finally:
        if relay:
            relay.close()
        subprocess.run(["docker", "rm", "-f", name], capture_output=True)


def run(coro):
    return asyncio.run(coro)


async def plan_against(ha: tuple[str, str], desired: dict):
    async with Client(*ha) as client:
        return plan(desired, await read_live(client, desired))


async def plan_and_apply(ha: tuple[str, str], desired: dict):
    async with Client(*ha) as client:
        before = plan(desired, await read_live(client, desired))
        await apply(client, before, log=lambda _: None)
        after = plan(desired, await read_live(client, desired))
    return before, after


async def snapshot(ha: tuple[str, str]) -> Live:
    async with Client(*ha) as client:
        return await read_live(client, None)


def area(name: str, **fields: object) -> dict:
    return {"name": name, "floor_id": None, "icon": None, "aliases": [], "labels": [], "picture": None, "temperature_entity_id": None, "humidity_entity_id": None} | fields


FIRST = {
    "format": 1,
    "prune": [],
    "labels": {
        "lights": {"name": "Lights", "color": "amber", "icon": "mdi:lightbulb", "description": None},
        "critical": {"name": "Critical", "color": "red", "icon": None, "description": "Never turn these off"},
    },
    "floors": {
        "ground": {"name": "Ground Floor", "level": 0, "icon": "mdi:home-floor-0", "aliases": ["Downstairs"]},
        "upstairs": {"name": "Upstairs", "level": 1, "icon": None, "aliases": []},
    },
    "areas": {
        "living_room": area("Lounge", floor_id="ground", labels=["lights"], aliases=["Den", "Front Room"]),
        "office": area("Home Office", floor_id="upstairs", icon="mdi:desk", labels=["critical", "lights"]),
    },
    "categories": {"automation": {"lighting": {"name": "Lighting", "icon": "mdi:lightbulb"}}},
}


def test_onboarding_areas_show_as_unmanaged(ha):
    result = run(plan_against(ha, {"format": 1, "prune": [], "areas": {}}))
    assert result.problems == []
    assert sorted(c.key for c in result.changes if c.action == "unmanaged") == ["bedroom", "kitchen", "living_room"]


def test_apply_creates_adopts_and_converges(ha):
    before, after = run(plan_and_apply(ha, FIRST))
    actions = {c.address: c.action for c in before.actions}
    assert actions == {
        "labels.lights": "create",
        "labels.critical": "create",
        "floors.ground": "create",
        "floors.upstairs": "create",
        "areas.living_room": "update",
        "areas.office": "create",
        "categories.automation.lighting": "create",
    }
    assert after.actions == [] and after.problems == []
    live = run(snapshot(ha))
    office = next(a for a in live.registries["areas"] if a["area_id"] == "office")
    assert office["name"] == "Home Office" and office["floor_id"] == "upstairs" and sorted(office["labels"]) == ["critical", "lights"]


def test_whole_object_ownership_clears_unset_fields(ha):
    second = json.loads(json.dumps(FIRST))
    second["areas"]["office"] = area("Home Office", floor_id="upstairs")
    second["floors"]["ground"]["aliases"] = []
    before, after = run(plan_and_apply(ha, second))
    office = next(c for c in before.actions if c.address == "areas.office")
    assert office.diff == {"icon": ("mdi:desk", None), "labels": (["critical", "lights"], [])}
    assert after.actions == []


def test_prune_deletes_and_references_block(ha):
    third = json.loads(json.dumps(FIRST)) | {"prune": ["areas", "labels"]}
    del third["labels"]["critical"]
    blocked = run(plan_against(ha, third))
    assert any("labels ['critical'] do not exist" in p for p in blocked.problems)
    with pytest.raises(ApplyError):
        run(plan_and_apply(ha, third))

    third["areas"]["office"]["labels"] = ["lights"]
    before, after = run(plan_and_apply(ha, third))
    deletes = sorted(c.address for c in before.actions if c.action == "delete")
    assert deletes == ["areas.bedroom", "areas.kitchen", "labels.critical"]
    assert after.actions == [] and after.changes == []


def test_import_round_trips_through_kcl(ha, tmp_path):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from test_kclgen import render_state

    live = run(snapshot(ha))
    desired = render_state(tmp_path, generate(live, ha[0]))
    result = run(plan_against(ha, desired))
    assert result.problems == [] and result.actions == []


def test_cli_plan_and_apply(ha, tmp_path):
    state = tmp_path / "state.json"
    desired = json.loads(json.dumps(FIRST)) | {"prune": ["labels"]}
    desired["areas"]["office"]["labels"] = ["lights"]
    del desired["labels"]["critical"]
    desired["areas"]["garden"] = area("Garden")
    state.write_text(json.dumps(desired))
    env = os.environ | {"HASS_URL": ha[0], "HASS_TOKEN": ha[1], "NO_COLOR": "1"}
    cmd = [sys.executable, "-m", "hastate.cli"]
    planned = subprocess.run([*cmd, "plan", "--state", str(state)], env=env, capture_output=True, text=True)
    assert planned.returncode == 0, planned.stderr
    assert "+ areas.garden" in planned.stdout and "Plan: 1 to create" in planned.stdout
    refused = subprocess.run([*cmd, "apply", "--state", str(state)], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    assert refused.returncode == 1 and "needs a terminal" in refused.stderr
    applied = subprocess.run([*cmd, "apply", "--state", str(state), "--yes"], env=env, capture_output=True, text=True)
    assert applied.returncode == 0, applied.stdout + applied.stderr
    assert "a new plan shows no changes" in applied.stdout
    bad = subprocess.run([*cmd, "plan", "--state", str(state)], env=env | {"HASS_TOKEN": "nope"}, capture_output=True, text=True)
    assert bad.returncode == 1 and "rejected the token" in bad.stderr


def test_renames_swaps_and_name_reuse_converge(ha):
    """Real HA must accept the temporary names and assign each key as the id."""
    live = run(snapshot(ha))
    names = {a["area_id"]: a["name"] for a in live.registries["areas"]}
    assert names["living_room"] == "Lounge" and names["office"] == "Home Office"
    desired = {
        "format": 1,
        "prune": ["areas"],
        "areas": {
            # Swap the names of two existing areas.
            "living_room": area("Home Office"),
            "office": area("Lounge"),
            # A new id takes the name of the pruned garden area.
            "yard": area("Garden"),
            # A new key that another new area uses as its name.
            "den": area("Study"),
            "study": area("Den"),
        },
    }
    _, after = run(plan_and_apply(ha, desired))
    assert after.actions == [] and after.problems == []
    names = {a["area_id"]: a["name"] for a in run(snapshot(ha)).registries["areas"]}
    assert names == {"living_room": "Home Office", "office": "Lounge", "yard": "Garden", "den": "Study", "study": "Den"}


def test_settings_collections_converge_and_round_trip(ha, tmp_path):
    live = run(snapshot(ha))
    demo = next(e for e in live.config_entries if e["domain"] == "demo")
    devices = [d for d in live.devices if d.get("config_entry_id") == demo["entry_id"] or demo["entry_id"] in (d.get("config_entries") or [])]
    device = devices[0]
    named = next(e for e in live.entities if e["platform"] == "demo" and e.get("device_id") and e.get("original_name") and not e.get("disabled_by"))
    domain = named["entity_id"].split(".")[0]
    desired = {
        "format": 1,
        "prune": [],
        "devices": {"first": {"match": {"id": device["id"]}, "name_by_user": "First Demo Device", "area_id": "den", "labels": ["lights"]}},
        "entities": {
            f"{domain}.haconfig_renamed": {
                "match": {"platform": "demo", "unique_id": named["unique_id"]},
                "icon": "mdi:test-tube",
                "area_id": "study",
                "aliases": ["Test tube"],
                "hidden": True,
            },
        },
        "integrations": {"demo": {"domain": "demo", "entry_id": demo["entry_id"], "title": "Demo Renamed"}},
    }
    before, after = run(plan_and_apply(ha, desired))
    assert {c.address for c in before.actions} == {"devices.first", f"entities.{domain}.haconfig_renamed", "integrations.demo"}
    assert after.actions == [] and after.problems == []

    live = run(snapshot(ha))
    entity = next(e for e in live.entities if e["unique_id"] == named["unique_id"] and e["platform"] == "demo")
    assert entity["entity_id"] == f"{domain}.haconfig_renamed" and entity["hidden_by"] == "user"
    # A new entity starts with HA's null placeholder for its own name, and the apply keeps it.
    assert live.entity_details[entity["entity_id"]]["aliases"] == [None, "Test tube"]
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from test_kclgen import render_state

    imported = render_state(tmp_path, generate(live, ha[0]))
    assert imported["devices"]["first_demo_device"]["area_id"] == "den"
    result = run(plan_against(ha, imported))
    assert result.problems == [] and result.actions == [], [c.address for c in result.actions]


def test_http_config_restarts_and_promotes(ha, tmp_path):
    """The apply stages the HTTP config, survives HA's restart, and promotes the config before HA reverts it."""
    state = tmp_path / "state.json"
    desired = {"format": 1, "prune": [], "http": {"ip_ban_enabled": False, "login_attempts_threshold": 5, "cors_allowed_origins": ["https://example.test"]}}
    state.write_text(json.dumps(desired))
    env = os.environ | {"HASS_URL": ha[0], "HASS_TOKEN": ha[1], "NO_COLOR": "1"}
    cmd = [sys.executable, "-m", "hastate.cli"]
    applied = subprocess.run([*cmd, "apply", "--state", str(state), "--yes"], env=env, capture_output=True, text=True, timeout=600)
    assert applied.returncode == 0, applied.stdout + applied.stderr
    assert "http: promoted" in applied.stdout and "a new plan shows no changes" in applied.stdout

    async def http_config():
        async with Client(*ha) as client:
            return await client.call("http/config")

    info = run(http_config())
    assert info["active_config_type"] == "stable" and info["pending"] is None
    assert info["stable"]["ip_ban_enabled"] is False and info["stable"]["login_attempts_threshold"] == 5
