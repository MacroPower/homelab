from __future__ import annotations

import asyncio

from fakeha import FakeHA

import pytest

from hastate import apps
from hastate.apply import ApplyError, apply, steps
from hastate.hacs import restart_needed
from hastate.http import effective, normalize, same_url, target_url
from hastate.kclgen import generate
from hastate.live import read_live
from hastate.plan import plan
from hastate.report import render

SSH_SCHEMA = [
    {"name": "authorized_keys", "multiple": True, "required": True, "type": "string"},
    {"name": "password", "required": True, "type": "string", "format": "password"},
    {"name": "apks", "multiple": True, "required": True, "type": "string"},
    {"name": "server", "type": "schema", "optional": True, "schema": [{"name": "tcp_forwarding", "required": True, "type": "boolean"}]},
]


def ssh() -> dict:
    return {
        "name": "Terminal & SSH", "version": "10.5.0", "version_latest": "10.5.0", "state": "started", "boot": "auto", "boot_config": "auto",
        "auto_update": False, "watchdog": True, "ingress_panel": True, "startup": "services", "repository": "core",
        "options": {"authorized_keys": ["ssh-ed25519 AAAA"], "password": "hunter2", "apks": [], "server": {"tcp_forwarding": False}},
        "schema": SSH_SCHEMA, "network": {"22/tcp": 22},
    }


def home(**extra) -> FakeHA:
    return FakeHA(
        apps={"core_ssh": ssh()},
        store={"core_mosquitto": {"name": "Mosquitto broker", "version_latest": "7.1.3", "options": {"logins": [], "require_certificate": False},
                                  "schema": [{"name": "logins", "type": "schema"}, {"name": "require_certificate", "type": "boolean"}],
                                  "network": {"1883/tcp": 1883}}},
        repositories=[{"slug": "core", "source": "core"}, {"slug": "cb646a50", "source": "https://github.com/hacs/addons"}],
        hacs=[
            {"id": "172733314", "full_name": "hacs/integration", "category": "integration", "installed": True, "installed_version": "2.0.5", "custom": False},
            {"id": "920548382", "full_name": "jeppesens/eufy-clean", "category": "integration", "installed": True, "installed_version": "v1.13.1", "custom": False},
            {"id": "111", "full_name": "thomasloven/lovelace-card-mod", "category": "plugin", "installed": False, "installed_version": "", "custom": False},
        ],
        http={
            "stable": {"server_port": 443, "ssl_certificate": "/ssl/fullchain.pem", "ssl_key": "/ssl/privkey.pem", "cors_allowed_origins": ["https://cast.home-assistant.io"],
                       "login_attempts_threshold": -1, "ip_ban_enabled": True, "use_x_frame_options": True, "ssl_profile": "modern",
                       "created_at": "x", "error": None, "error_message": None},
            "pending": None, "revert_at": None, "active_config_type": "stable",
            "default": {"server_port": 80, "cors_allowed_origins": ["https://cast.home-assistant.io"], "login_attempts_threshold": -1, "ip_ban_enabled": True,
                        "ssl_profile": "modern", "use_x_frame_options": True, "created_at": "y", "error": None, "error_message": None},
        },
        **extra,
    )


def state(**collections: object) -> dict[str, object]:
    return {"format": 1, "prune": [], **collections}


def run(coro):
    return asyncio.run(coro)


def planned(ha: FakeHA, desired: dict, url: str = "https://hass.example:443"):
    return plan(desired, run(read_live(ha, desired)), url)


def converge(ha: FakeHA, desired: dict):
    before = planned(ha, desired)
    assert before.problems == [], before.problems
    run(apply(ha, before, log=lambda _: None))
    return before, planned(ha, desired)


def test_app_options_merge_and_hide_secrets():
    ha = home()
    desired = state(apps={"core_ssh": {"options": {"password": "!secret ssh_password", "server": {"tcp_forwarding": True}}, "watchdog": False}})
    before = planned(ha, desired)
    change = before.actions[0]
    assert change.diff["options.server"] == ({"tcp_forwarding": False}, {"tcp_forwarding": True})
    text = render(before, "u")
    assert "hunter2" not in text and "!secret ssh_password" in text and "AAAA" not in text
    run(apply(ha, before, log=lambda _: None))
    app = ha.apps["core_ssh"]
    assert app["options"]["password"] == "!secret ssh_password" and app["options"]["authorized_keys"] == ["ssh-ed25519 AAAA"]
    assert app["watchdog"] is False and app["restarts"] == 1
    assert planned(ha, desired).actions == []


def test_app_install_configure_and_start():
    ha = home()
    desired = state(apps={"core_ssh": {}, "core_mosquitto": {"version": "7.1.3", "options": {"require_certificate": True}, "started": True}})
    before, after = converge(ha, desired)
    assert [s.description for s in steps(before)] == ["install apps.core_mosquitto", "configure apps.core_mosquitto", "start apps.core_mosquitto"]
    assert after.actions == [] and ha.apps["core_mosquitto"]["state"] == "started"
    assert ha.apps["core_mosquitto"]["options"] == {"logins": [], "require_certificate": True}


def test_app_pins_and_store():
    ha = home()
    ha.apps["core_ssh"]["version_latest"] = "10.6.0"
    behind = planned(ha, state(apps={"core_ssh": {"version": "10.5.1"}}))
    assert behind.actions == [] and any("cannot install another version" in w for w in behind.warnings)
    bump = planned(ha, state(apps={"core_ssh": {"version": "10.6.0"}}))
    assert [s.description for s in steps(bump)] == ["update apps.core_ssh to 10.6.0", "configure apps.core_ssh"]
    missing = planned(ha, state(apps={"core_nope": {}}))
    assert any("store has no app 'core_nope'" in p for p in missing.problems)
    pinned = planned(ha, state(apps={"core_mosquitto": {"version": "7.0.0"}}))
    assert any("installs only the latest" in p for p in pinned.problems)


def test_app_problems():
    ha = home()
    ha.apps["core_ssh"]["boot_config"] = "manual_only"
    ha.apps["core_ssh"]["startup"] = "once"
    result = planned(ha, state(apps={"core_ssh": {"boot": "manual", "watchdog": True, "network": {"22": 22}, "options": {"nope": 1, "apks": None}}}))
    text = "\n".join(result.problems)
    assert "boot is manual_only" in text and "ignores a watchdog" in text and "no port '22'" in text
    assert "no option 'nope'" in text and "options.apks is None" in text


def test_unmanaged_and_pruned_apps_and_repositories():
    ha = home()
    kept = planned(ha, state(apps={}, app_repositories=[]))
    assert {(c.action, c.address) for c in kept.changes} == {("unmanaged", "apps.core_ssh"), ("unmanaged", "app_repositories.cb646a50")}
    desired = state(apps={}, app_repositories=["https://github.com/esphome/home-assistant-addon"], prune=["apps", "app_repositories"])
    _, after = converge(ha, desired)
    assert after.actions == [] and ha.apps == {}
    assert {r["source"] for r in ha.repositories} == {"core", "https://github.com/esphome/home-assistant-addon"}


def test_hacs_install_update_and_prune():
    ha = home()
    desired = state(
        hacs={
            "hacs/integration": {"category": "integration", "version": "2.0.5"},
            "Jeppesens/Eufy-Clean": {"category": "integration", "version": "v1.14.0"},
            "thomasloven/lovelace-card-mod": {"category": "plugin", "version": "v4.0.0"},
            "someone/custom": {"category": "theme", "version": "1.0"},
        }
    )
    before, after = converge(ha, desired)
    assert {(c.action, c.address) for c in before.actions} == {
        ("update", "hacs.Jeppesens/Eufy-Clean"), ("create", "hacs.thomasloven/lovelace-card-mod"), ("create", "hacs.someone/custom")
    }
    assert after.actions == []
    custom = next(r for r in ha.hacs_repos if r["full_name"] == "someone/custom")
    assert custom["installed"] and custom["installed_version"] == "1.0"
    pruned = planned(ha, {**desired, "hacs": {"hacs/integration": desired["hacs"]["hacs/integration"]}, "prune": ["hacs"]})
    assert {c.address for c in pruned.actions} == {"hacs.jeppesens/eufy-clean", "hacs.thomasloven/lovelace-card-mod", "hacs.someone/custom"}


def test_hacs_self_never_pruned_and_runs_first():
    ha = home()
    pruned = planned(ha, state(hacs={}, prune=["hacs"]))
    assert "hacs.hacs/integration" not in {c.address for c in pruned.actions}
    order = planned(ha, state(hacs={"jeppesens/eufy-clean": {"category": "integration", "version": "v2"}, "hacs/integration": {"category": "integration", "version": "2.1.0"}}))
    assert [s.description for s in steps(order)][0] == "download hacs.hacs/integration 2.1.0"


def test_hacs_missing_is_a_problem():
    ha = home()
    ha.hacs_repos = None
    result = planned(ha, state(hacs={}))
    assert any("HACS is not installed" in p for p in result.problems)


def test_http_matches_stable_and_diffs_against_defaults():
    ha = home()
    same = planned(ha, state(http={"server_port": 443, "ssl_certificate": "/ssl/fullchain.pem", "ssl_key": "/ssl/privkey.pem"}))
    assert same.actions == [] and same.problems == []
    change = planned(ha, state(http={"server_port": 443, "ssl_certificate": "/ssl/fullchain.pem", "ssl_key": "/ssl/privkey.pem", "ip_ban_enabled": False})).actions[0]
    assert change.diff == {"ip_ban_enabled": (True, False)}
    dropped = planned(ha, state(http={})).actions[0]
    assert dropped.diff["server_port"] == (443, 80) and any("HA moves to http://hass.example" in n for n in dropped.notes)


def test_http_pending_blocks():
    ha = home()
    ha.http["pending"] = {"server_port": 8443, "created_at": "z", "error": None, "error_message": None}
    result = planned(ha, state(http={"server_port": 443, "ssl_certificate": "/ssl/fullchain.pem", "ssl_key": "/ssl/privkey.pem"}))
    assert any("pending HTTP config" in p for p in result.problems)


def test_http_normalization_and_urls():
    assert normalize({"trusted_proxies": ["10.0.0.1", "10.1.0.0/16"], "server_host": "0.0.0.0"}) == {"trusted_proxies": ["10.0.0.1/32", "10.1.0.0/16"], "server_host": ["0.0.0.0"]}
    assert effective({"server_port": 8443, "ip_ban_enabled": None}, {"server_port": 80, "ip_ban_enabled": True, "created_at": "x"}) == {"server_port": 8443, "ip_ban_enabled": True}
    assert target_url("https://hass.example", {"server_port": 443, "ssl_certificate": "/c"}) == "https://hass.example"
    assert target_url("https://hass.example", {"server_port": 8123}) == "http://hass.example:8123"


def test_apps_without_a_supervisor():
    ha = FakeHA()
    result = planned(ha, state(apps={}, app_repositories=[]))
    assert any("without a Supervisor" in p for p in result.problems)
    from hastate.kclgen import generate

    assert "apps =" not in generate(run(read_live(ha, None)), "u")


def test_failed_validation_hides_option_values():
    ha = home()
    ha.apps["core_ssh"]["schema"].append({"name": "bad", "type": "string"})
    before = planned(ha, state(apps={"core_ssh": {"options": {"bad": "x"}}}))
    assert before.problems == []
    with pytest.raises(ApplyError) as err:
        run(apply(ha, before, log=lambda _: None))
    assert "Invalid option 'bad'" in str(err.value) and "hunter2" not in str(err.value) and "AAAA" not in str(err.value)


def test_free_form_options_stay_hidden_and_out_of_the_import():
    ha = home()
    ha.apps["core_ssh"]["options"]["env_vars"] = [{"name": "GF_SMTP_PASSWORD", "value": "s3cret"}]
    ha.apps["core_ssh"]["options"]["log_level"] = "info"
    ha.apps["core_ssh"]["schema"] += [
        {"name": "env_vars", "type": "schema", "multiple": True, "schema": [{"name": "name", "type": "string"}, {"name": "value", "type": "string"}]},
        {"name": "log_level", "type": "select", "options": ["info", "debug"]},
    ]
    assert {"env_vars", "password"} <= apps.sensitive_keys(ha.apps["core_ssh"])
    assert apps.importable_keys(ha.apps["core_ssh"]) == {"server", "log_level"}
    text = generate(run(read_live(ha, None)), "u")
    assert "s3cret" not in text and "hunter2" not in text and "AAAA" not in text
    assert 'log_level = "info"' in text and "not imported, because they can hold secrets or free text: apks, authorized_keys, env_vars, password" in text


def test_repository_and_app_in_one_apply():
    url = "https://github.com/alexbelgium/hassio-addons"
    slug = apps.repository_slug(url)
    ha = home()
    ha.store[f"{slug}_joplin"] = {"name": "Joplin", "version_latest": "3.0.0", "repository": slug, "options": {}, "schema": []}
    desired = state(app_repositories=["https://github.com/hacs/addons", url], apps={"core_ssh": {}, f"{slug}_joplin": {"started": True}})
    before, after = converge(ha, desired)
    assert [s.description for s in steps(before)][:2] == [f"add app_repositories.{slug}", f"install apps.{slug}_joplin"]
    assert after.actions == [] and ha.apps[f"{slug}_joplin"]["state"] == "started"


def test_uninstalls_run_before_installs():
    ha = home()
    desired = state(apps={"core_mosquitto": {"started": True}}, prune=["apps"])
    before = planned(ha, desired)
    assert [s.description for s in steps(before)] == ["uninstall apps.core_ssh", "install apps.core_mosquitto", "configure apps.core_mosquitto", "start apps.core_mosquitto"]


def test_install_checks_options_after_the_install():
    ha = home()
    before = planned(ha, state(apps={"core_ssh": {}, "core_mosquitto": {"options": {"nope": 1}}}))
    assert before.problems == []
    with pytest.raises(ApplyError) as err:
        run(apply(ha, before, log=lambda _: None))
    assert "configure apps.core_mosquitto failed" in str(err.value) and "no option 'nope'" in str(err.value)


def test_credentialed_repositories_stay_secret():
    ha = home()
    ha.repositories.append({"slug": "deadbeef", "source": "https://me:ghp_token@github.com/me/apps"})
    from hastate.report import render

    result = planned(ha, state(app_repositories=["https://github.com/hacs/addons"]))
    assert "ghp_token" not in render(result, "u")
    text = generate(run(read_live(ha, None)), "u")
    assert "ghp_token" not in text and "because their URLs hold credentials: https://(sensitive)@github.com/me/apps" in text


def test_once_apps_import_without_started_or_watchdog():
    ha = home()
    ha.apps["core_ssh"]["startup"] = "once"
    text = generate(run(read_live(ha, None)), "u")
    block = text[text.index("core_ssh = {"):]
    block = block[: block.index("}")]
    assert "started" not in block and "watchdog" not in block


def test_hacs_deletes_carry_their_category():
    ha = home()
    ha.hacs_repos[2].update({"installed": True, "installed_version": "v3.0.0"})
    pruned = planned(ha, state(hacs={"hacs/integration": {"category": "integration", "version": "2.0.5"}, "jeppesens/eufy-clean": {"category": "integration", "version": "v1.13.1"}}, prune=["hacs"]))
    assert [c.address for c in pruned.actions] == ["hacs.thomasloven/lovelace-card-mod"]
    assert not restart_needed(pruned.actions)


def test_hacs_short_commits_import_without_renovate():
    ha = home()
    ha.hacs_repos[2].update({"installed": True, "installed_version": "abc1234"})
    text = generate(run(read_live(ha, None)), "u")
    block = text[text.index('"thomasloven/lovelace-card-mod" = {'):]
    block = block[: block.index("}")]
    assert "renovate" not in block and "full 40-character commit hash" in block


def test_http_urls_keep_ipv6_brackets():
    assert target_url("https://[fd00::10]", {"server_port": 8123}) == "http://[fd00::10]:8123"
    assert same_url(target_url("https://[fd00::10]", {"server_port": 443, "ssl_certificate": "/c"}), "https://[fd00::10]")


def test_http_behind_a_proxy_keeps_the_url():
    ha = home()
    ha.http["stable"] = {"server_port": 8123, "use_x_forwarded_for": True, "trusted_proxies": ["172.30.33.0/24"], "created_at": "x"}
    change = planned(ha, state(http={"server_port": 8124, "use_x_forwarded_for": True, "trusted_proxies": ["172.30.33.0/24"]}), "https://ha.example")
    assert not any("moves to" in n for n in change.actions[0].notes)
    assert any("through a proxy" in w for w in change.warnings)


def test_http_certificate_without_key():
    ha = home()
    combined = planned(ha, state(http={"server_port": 443, "ssl_certificate": "/ssl/combined.pem"}))
    assert combined.problems == []
    keyless = planned(ha, state(http={"server_port": 443, "ssl_key": "/ssl/privkey.pem"}))
    assert any("ssl_key requires ssl_certificate" in p for p in keyless.problems)


def test_stops_and_restarts_run_before_starts():
    ha = home()
    desired = state(apps={"core_ssh": {"started": False}, "core_mosquitto": {"started": True}})
    order = [s.description for s in steps(planned(ha, desired))]
    assert order.index("stop apps.core_ssh") < order.index("start apps.core_mosquitto"), order
    moved = state(apps={"core_ssh": {"network": {"22/tcp": 2222}}, "core_mosquitto": {"network": {"1883/tcp": 22}, "started": True}})
    order = [s.description for s in steps(planned(ha, moved))]
    assert order.index("restart apps.core_ssh") < order.index("start apps.core_mosquitto"), order


def test_options_compare_in_their_stored_types():
    ha = home()
    ha.apps["core_ssh"]["schema"].append({"name": "baud", "type": "select", "options": ["9600", "460800"]})
    ha.apps["core_ssh"]["options"]["baud"] = "9600"
    desired = state(apps={"core_ssh": {"options": {"baud": 460800}}})
    before, after = converge(ha, desired)
    assert before.actions[0].diff == {"options.baud": ("9600", "460800")}
    assert after.actions == [] and ha.apps["core_ssh"]["options"]["baud"] == "460800"


def test_options_that_move_to_a_secret_stay_hidden():
    from hastate.report import render

    ha = home()
    ha.apps["core_ssh"]["schema"].append({"name": "repository", "type": "string"})
    ha.apps["core_ssh"]["options"]["repository"] = "https://me:ghp_TOKEN@github.com/me/config.git"
    result = planned(ha, state(apps={"core_ssh": {"options": {"repository": "!secret git_repo"}}}))
    assert "ghp_TOKEN" not in render(result, "u")


def test_import_writes_device_paths_and_skips_empty_options():
    ha = home()
    ha.apps["core_ssh"]["schema"] += [{"name": "device", "type": "select", "options": ["/dev/serial/by-id/usb-Stick_1CDB-if00"]},
                                      {"name": "flow", "type": "select", "options": ["none", "hardware"]}]
    ha.apps["core_ssh"]["options"] |= {"device": "/dev/serial/by-id/usb-Stick_1CDB-if00", "flow": None}
    text = generate(run(read_live(ha, None)), "u")
    assert 'device = "/dev/serial/by-id/usb-Stick_1CDB-if00"' in text and "flow" in text and "flow = None" not in text
