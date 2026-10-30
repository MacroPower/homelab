from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest
import yaml

from hastate.kclgen import generate, kcl_key, kcl_string
from hastate.plan import Live, plan

HACONFIG = Path(__file__).resolve().parents[2]


def render_state(module: Path, state_kcl: str) -> dict:
    """Render a scratch module that sets HomeAssistant.state, and return the state document."""
    (module / "kcl.mod").write_text(
        '[package]\nname = "roundtrip"\nedition = "v0.11.1"\nversion = "0.0.1"\n\n'
        f'[dependencies]\nhaconfig = {{ path = "{HACONFIG}" }}\n\n'
        '[profile]\nentries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]\n'
    )
    (module / "state.k").write_text(state_kcl)
    (module / "main.k").write_text("import haconfig.models.frontend\n\nconfig = frontend.HomeAssistant {state = hass_state}\n")
    out = subprocess.run(["kcl", "run", "--no_style", "--quiet"], cwd=module, capture_output=True, text=True)
    assert out.returncode == 0, out.stderr
    docs = [d for d in yaml.safe_load_all(out.stdout) if d and d.get("path") == "@state"]
    assert len(docs) == 1, out.stdout
    return json.loads(docs[0]["content"])


def snapshot() -> Live:
    return Live(
        "2026.10.4",
        {
            "floors": [
                {"floor_id": "2nd_floor", "name": "2nd Floor", "level": 2, "icon": None, "aliases": ["Upstairs", "Top"]},
                {"floor_id": "ground", "name": "Ground", "level": 0, "icon": "mdi:home-floor-0", "aliases": []},
            ],
            "areas": [
                {"area_id": "type", "name": "Café ${room}", "floor_id": "ground", "icon": None, "aliases": [], "labels": ["lights"], "picture": None, "temperature_entity_id": None, "humidity_entity_id": None},
                {"area_id": "attic", "name": 'Attic "loft"', "floor_id": None, "icon": "mdi:home-roof", "aliases": ["Loft"], "labels": [], "picture": "/api/image/serve/abc/512x512", "temperature_entity_id": None, "humidity_entity_id": None},
            ],
            "labels": [{"label_id": "lights", "name": "Lights", "color": "amber", "icon": None, "description": "Every light"}],
        },
        categories={
            "automation": [{"category_id": "01A", "name": "Lighting", "icon": "mdi:lightbulb"}, {"category_id": "01B", "name": "lighting!", "icon": None}],
            "script": [],
        },
    )


def test_quoting():
    assert kcl_key("living_room") == "living_room"
    assert kcl_key("type") == '"type"'
    assert kcl_key("2nd_floor") == '"2nd_floor"'
    assert kcl_string("a ${b}") == '"a \\${b}"'


@pytest.mark.skipif(shutil.which("kcl") is None, reason="kcl is not on PATH")
def test_import_round_trips_to_an_empty_plan(tmp_path: Path):
    live = snapshot()
    desired = render_state(tmp_path, generate(live, "http://ha"))
    result = plan(desired, live)
    assert result.problems == []
    assert result.changes == [], [c.address for c in result.changes]
    assert desired["areas"]["type"]["name"] == "Café ${room}"
    assert sorted(desired["categories"]["automation"]) == ["lighting", "lighting_2"]
