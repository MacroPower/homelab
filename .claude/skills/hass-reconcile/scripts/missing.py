# /// script
# requires-python = ">=3.12"
# dependencies = ["pyyaml>=6"]
# ///
"""List what the live Home Assistant holds that the repo's state does not declare.

Usage:
  uv run missing.py --repo REPO --import LIVE_K --state STATE_JSON

LIVE_K is a file that `task hass:import` wrote from the live instance.
STATE_JSON is the repo's rendered state, `.cache/hass/home/hass/state.json`,
which `task hass:plan` writes. The script renders LIVE_K through haconfig in
a scratch module next to it, compares the two state documents, and prints
JSON with four keys:

- missing: each live object that git lacks, by collection, with the key
  that LIVE_K uses for it, so you can copy its block.
- fields: each object that both hold, with the fields that live sets and
  git does not declare. Only the collections whose objects git owns field
  by field appear here: devices, entities, integrations, and apps.
- collections: each collection that live holds and git leaves unmanaged.
- unmatched: each git object that the script cannot match against LIVE_K,
  such as a device that git matches by identifier.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml

KCL_NAMES = {
    "devices": {"name_by_user": "name", "area_id": "area", "labels": "labels", "disabled": "disabled"},
    "entities": {
        "name": "name", "icon": "icon", "area_id": "area", "labels": "labels", "aliases": "aliases",
        "hidden": "hidden", "disabled": "disabled", "device_class": "deviceClass", "categories": "categories",
    },
    "integrations": {
        "title": "title", "disabled": "disabled", "pref_disable_new_entities": "disableNewEntities",
        "pref_disable_polling": "disablePolling",
    },
    "apps": {
        "version": "version", "boot": "boot", "auto_update": "autoUpdate", "watchdog": "watchdog",
        "ingress_panel": "ingressPanel", "started": "started",
    },
}
"""The KCL name of each field in the state document, for the collections that report fields."""


def render(repo: Path, live_k: Path) -> dict[str, Any]:
    """Render LIVE_K through haconfig and return its state document."""
    module = live_k.parent / "render"
    shutil.rmtree(module, ignore_errors=True)
    module.mkdir(parents=True)
    (module / "kcl.mod").write_text(
        '[package]\nname = "reconcile"\nedition = "v0.11.1"\nversion = "0.0.1"\n\n'
        f'[dependencies]\nhaconfig = {{ path = "{repo / "haconfig"}" }}\n\n'
        '[profile]\nentries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]\n'
    )
    shutil.copy(live_k, module / "state.k")
    (module / "main.k").write_text("import haconfig.models.frontend\n\nconfig = frontend.HomeAssistant {state = hass_state}\n")
    out = subprocess.run(["kcl", "run", "--no_style", "--quiet"], cwd=module, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"kcl cannot render {live_k}:\n{out.stderr}")
    for doc in yaml.safe_load_all(out.stdout):
        if doc and doc.get("path") == "@state":
            return json.loads(doc["content"])
    sys.exit(f"the render of {live_k} holds no state document")


def compare(git: dict[str, Any], live: dict[str, Any]) -> dict[str, Any]:
    missing: dict[str, list[Any]] = {}
    fields: dict[str, list[Any]] = {}
    collections: list[str] = []
    unmatched: list[str] = []

    for coll in ("floors", "areas", "labels", "devices", "entities", "integrations", "apps", "app_repositories", "hacs", "http", "categories"):
        if coll in live and coll not in git and live[coll]:
            collections.append(coll)

    for coll in ("floors", "areas", "labels"):
        if coll in git:
            missing[coll] = sorted(k for k in live.get(coll, {}) if k not in git[coll])

    if "categories" in git:
        have = {(s, c["name"].casefold()) for s, cs in git["categories"].items() for c in cs.values()}
        missing["categories"] = [
            {"scope": s, "import_key": k, "name": c["name"]}
            for s, cs in live.get("categories", {}).items() for k, c in cs.items() if (s, c["name"].casefold()) not in have
        ]

    if "devices" in git:
        by_id = {d["match"]["id"]: (k, d) for k, d in live.get("devices", {}).items()}
        seen = set()
        for key, dev in git["devices"].items():
            device_id = dev.get("match", {}).get("id")
            if device_id is None:
                unmatched.append(f"devices.{key}: git matches it by identifier or connection")
                continue
            seen.add(device_id)
            if device_id in by_id:
                _fields(fields, "devices", key, by_id[device_id][0], dev, by_id[device_id][1])
        missing["devices"] = [{"import_key": k, "id": i} for i, (k, _) in by_id.items() if i not in seen]

    if "entities" in git:
        for key, ent in git["entities"].items():
            if key in live.get("entities", {}):
                _fields(fields, "entities", key, key, ent, live["entities"][key])
        renamed = {k for k, e in git["entities"].items() if "match" in e}
        missing["entities"] = sorted(k for k in live.get("entities", {}) if k not in git["entities"])
        if renamed:
            unmatched += [f"entities.{k}: git renames it through match, so its live entity id differs" for k in sorted(renamed)]

    if "integrations" in git:
        by_entry = {i["entry_id"]: (k, i) for k, i in live.get("integrations", {}).items()}
        seen = set()
        for key, spec in git["integrations"].items():
            entry = spec.get("entry_id")
            if entry is None:
                found = [i for i, (_, v) in by_entry.items() if v["domain"] == spec["domain"] and v.get("title") == spec.get("title")]
                if len(found) != 1:
                    unmatched.append(f"integrations.{key}: git matches it by title, and the import holds {len(found)} such entries")
                    continue
                entry = found[0]
            seen.add(entry)
            if entry in by_entry:
                _fields(fields, "integrations", key, by_entry[entry][0], spec, by_entry[entry][1])
        missing["integrations"] = [{"import_key": k, "domain": v["domain"], "entry_id": i} for i, (k, v) in by_entry.items() if i not in seen]

    if "apps" in git:
        for slug, spec in git["apps"].items():
            if slug in live.get("apps", {}):
                _fields(fields, "apps", slug, slug, spec, live["apps"][slug])
        missing["apps"] = sorted(s for s in live.get("apps", {}) if s not in git["apps"])

    if "app_repositories" in git:
        missing["app_repositories"] = sorted(u for u in live.get("app_repositories", []) if u not in git["app_repositories"])

    if "hacs" in git:
        have = {k.lower() for k in git["hacs"]}
        missing["hacs"] = sorted(k for k in live.get("hacs", {}) if k.lower() not in have)

    return {
        "missing": {c: v for c, v in missing.items() if v},
        "fields": {c: v for c, v in fields.items() if v},
        "collections": collections,
        "unmatched": unmatched,
    }


def _fields(out: dict[str, list[Any]], coll: str, key: str, import_key: str, git: dict[str, Any], live: dict[str, Any]) -> None:
    """Record the fields that LIVE sets and GIT does not declare, by their KCL names."""
    names = KCL_NAMES[coll]
    found = {names[f]: v for f, v in live.items() if f in names and f not in git}
    if coll == "apps":
        found |= {f"options.{k}": v for k, v in (live.get("options") or {}).items() if k not in (git.get("options") or {})}
        found |= {f"network.{p}": v for p, v in (live.get("network") or {}).items() if p not in (git.get("network") or {})}
    if found:
        out.setdefault(coll, []).append({"key": key, "import_key": import_key, "fields": found})


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--import", dest="live_k", type=Path, required=True)
    parser.add_argument("--state", type=Path, required=True)
    args = parser.parse_args()
    git = json.loads(args.state.read_text())
    live = render(args.repo.resolve(), args.live_k.resolve())
    json.dump(compare(git, live), sys.stdout, indent=2, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
