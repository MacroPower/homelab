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


def render_module(module: Path, state_kcl: str, secrets: str = "{}") -> subprocess.CompletedProcess[str]:
    """Render a scratch module that sets HomeAssistant.state, and return the finished kcl run."""
    (module / "kcl.mod").write_text(
        '[package]\nname = "roundtrip"\nedition = "v0.11.1"\nversion = "0.0.1"\n\n'
        f'[dependencies]\nhaconfig = {{ path = "{HACONFIG}" }}\n\n'
        '[profile]\nentries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]\n'
    )
    (module / "state.k").write_text(state_kcl)
    (module / "main.k").write_text(f"import haconfig.models.frontend\n\nconfig = frontend.HomeAssistant {{state = hass_state, secrets = {secrets}}}\n")
    return subprocess.run(["kcl", "run", "--no_style", "--quiet"], cwd=module, capture_output=True, text=True)


def render_state(module: Path, state_kcl: str) -> dict:
    """Render a scratch module that sets HomeAssistant.state, and return the state document."""
    out = render_module(module, state_kcl)
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
        devices=[
            {"id": "a" * 32, "name": "Hue lamp", "name_by_user": "Reading Lamp", "area_id": "type", "labels": ["lights"], "disabled_by": None, "manufacturer": "Signify", "model": "LCT015"},
            {"id": "b" * 32, "name": "Hue lamp", "name_by_user": None, "area_id": "attic", "labels": [], "disabled_by": "user"},
            {"id": "c" * 32, "name": "Untouched", "name_by_user": None, "area_id": None, "labels": [], "disabled_by": "integration"},
        ],
        entities=[
            {"entity_id": "light.reading", "platform": "hue", "unique_id": "1", "name": "Reading", "icon": "mdi:lamp", "area_id": None, "labels": ["lights"],
             "hidden_by": "user", "disabled_by": None, "categories": {}, "device_id": "a" * 32, "original_name": None},
            {"entity_id": "automation.night", "platform": "automation", "unique_id": "2", "name": None, "icon": None, "area_id": None, "labels": [],
             "hidden_by": None, "disabled_by": "user", "categories": {"automation": "01A"}, "device_id": None, "original_name": "Night"},
            {"entity_id": "sensor.idle", "platform": "demo", "unique_id": "3", "name": None, "icon": None, "area_id": None, "labels": [],
             "hidden_by": "integration", "disabled_by": "integration", "categories": {}, "device_id": None, "original_name": "Idle"},
        ],
        entity_details={
            "light.reading": {"aliases": ["Book light", None], "device_class": None},
            "automation.night": {"aliases": [], "device_class": None},
            "sensor.idle": {"aliases": [], "device_class": "power"},
        },
        config_entries=[
            {"entry_id": "01H", "domain": "hue", "title": "Hue ${x}", "source": "user", "disabled_by": None, "pref_disable_new_entities": True, "pref_disable_polling": False},
            {"entry_id": "01M", "domain": "met", "title": "Home", "source": "user", "disabled_by": "user", "pref_disable_new_entities": False, "pref_disable_polling": False},
            {"entry_id": "01N", "domain": "met", "title": "Cabin", "source": "user", "disabled_by": None, "pref_disable_new_entities": False, "pref_disable_polling": True},
            {"entry_id": "01Z", "domain": "zha", "title": "Ignored", "source": "ignore", "disabled_by": None, "pref_disable_new_entities": False, "pref_disable_polling": False},
        ],
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


@pytest.mark.skipif(shutil.which("kcl") is None, reason="kcl is not on PATH")
def test_import_writes_only_user_settings(tmp_path: Path):
    desired = render_state(tmp_path, generate(snapshot(), "http://ha"))
    assert sorted(desired["devices"]) == ["hue_lamp", "reading_lamp"]
    assert desired["devices"]["hue_lamp"] == {"match": {"id": "b" * 32}, "area_id": "attic", "disabled": True}
    assert sorted(desired["entities"]) == ["automation.night", "light.reading", "sensor.idle"]
    assert desired["entities"]["light.reading"]["aliases"] == ["Book light"]
    assert desired["entities"]["automation.night"] == {"disabled": True, "categories": {"automation": "Lighting"}}
    assert desired["entities"]["sensor.idle"] == {"device_class": "power"}
    assert sorted(desired["integrations"]) == ["hue", "met_cabin", "met_home"]
    assert desired["integrations"]["met_home"] == {"domain": "met", "entry_id": "01M", "title": "Home", "disabled": True}


SECRET_STATE = """import haconfig.models.frontend.state as hstate
import haconfig.tags

hass_state = hstate.State {{
{body}
}}
"""


@pytest.mark.skipif(shutil.which("kcl") is None, reason="kcl is not on PATH")
@pytest.mark.parametrize(
    ("body", "error"),
    [
        ('    devices.lamp = {match.id = "' + "a" * 32 + '", name = tags.secret("pw")}', "works only in apps.<slug>.options"),
        ('    apps.core_mosquitto.options.url = "mqtt://u:" + tags.secret("pw")', "must be an app option's whole value"),
    ],
)
def test_render_rejects_misplaced_secrets(tmp_path: Path, body: str, error: str):
    out = render_module(tmp_path, SECRET_STATE.format(body=body), '{pw = "fake"}')
    assert out.returncode != 0 and error in out.stderr, out.stderr


@pytest.mark.skipif(shutil.which("kcl") is None, reason="kcl is not on PATH")
def test_render_keeps_secrets_in_app_options(tmp_path: Path):
    out = render_module(tmp_path, SECRET_STATE.format(body='    apps.core_mosquitto.options.password = tags.secret("pw")'), '{pw = "fake"}')
    assert out.returncode == 0, out.stderr
    doc = next(d for d in yaml.safe_load_all(out.stdout) if d and d.get("path") == "@state")
    assert json.loads(doc["content"])["apps"]["core_mosquitto"]["options"]["password"] == "!secret pw"


def test_comments_cannot_break_out():
    from hastate.kclgen import comment

    assert comment("TV\n    }\n    prune = [\"areas\"]\u2028x\x00") == 'TV } prune = ["areas"] x'


def test_import_leaves_out_email_titles():
    live = snapshot()
    live.config_entries.append(
        {"entry_id": "01G", "domain": "google", "title": "me@example.com", "source": "user", "disabled_by": None, "pref_disable_new_entities": False, "pref_disable_polling": False}
    )
    live.config_entries.append(
        {"entry_id": "01G2", "domain": "google", "title": "you@example.com", "source": "user", "disabled_by": None, "pref_disable_new_entities": False, "pref_disable_polling": False}
    )
    text = generate(live, "u")
    assert "example.com" not in text and 'entryId = "01G"' in text and "google_2 = {" in text


def test_import_leaves_out_email_device_names():
    live = snapshot()
    live.devices.append({"id": "d" * 32, "name": "me@example.com", "name_by_user": None, "area_id": "attic", "labels": [], "disabled_by": None,
                         "manufacturer": "Google", "model": "Gmail"})
    text = generate(live, "u")
    assert "example.com" not in text and "google_gmail = {" in text


def test_import_keeps_renovate_on_digit_tags():
    from hastate.kclgen import COMMIT

    assert COMMIT.fullmatch("abc1234") and not COMMIT.fullmatch("20240115") and not COMMIT.fullmatch("v1.2.3")
