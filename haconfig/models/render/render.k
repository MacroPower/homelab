import manifests
import regex
import yaml

import models.backend
import models.frontend
import models.frontend.common
import models.metadata as hmd
import tags

# render.k is the render entry of a Home Assistant config module, wired with
#   [profile] entries = ["main.k", "${haconfig:KCL_MOD}/models/render/render.k"]
# It prints one YAML stream of {path, content} documents, and never writes to
# disk. `task hass:render` splits the stream into a config directory.

# lambda: return the sorted values that occur more than once
duplicated = lambda _dpData: [str] -> [str] {
    sorted({_dpData[_dpI] = None for _dpI in range(len(_dpData)) if _dpData[_dpI] in _dpData[_dpI + 1:]})
}

# lambda: return one domain of a DomainMapping, or Undefined when it is absent
domainOf = lambda m: any, d: str -> any {
    m[d] if d in m else Undefined
}

# One config directory has one configuration.yaml, so the main package must
# hold exactly one HomeAssistant instance.
__renderRootFrontendInstances__ = [inst for inst in frontend.HomeAssistant.instances() if typeof(inst) == "HomeAssistant"]
assert len(__renderRootFrontendInstances__) == 1, "expected exactly one frontend.HomeAssistant in the main package, found ${len(__renderRootFrontendInstances__)}"
__root__ = __renderRootFrontendInstances__[0]

__renderRootBackendInstance__ = backend.HomeAssistantBackend(__root__)
__renderPackageBackendInstances__ = [
    backend.PackageBackend(_p) for _, _p in __root__.packages or {} if _p
]

# Identity checks over every package. HA keeps only the first of two
# dict-merged keys and drops a second automation with the same id. It reports
# both only in its log, so the render fails instead.
__templateDomainKeys__ = ["triggers", "conditions", "actions", "variables"]
__objectIdDomains__ = ["script", "input_boolean", "input_button", "input_number", "input_select", "input_text", "input_datetime", "timer", "counter", "schedule"]

__packageNames__ = [_b.config.name for _b in __renderPackageBackendInstances__]
__automationIds__ = [_a.id for _b in __renderPackageBackendInstances__ for _a in domainOf(_b.hass, "automation") or []]
# HA scopes a unique_id to its domain and platform, so a sensor and a
# binary_sensor may share one. Each entry pairs the domain with the unique_id.
__templateUniqueIds__ = ["{}:{}".format(_d, _e.unique_id) for _b in __renderPackageBackendInstances__ for _s in domainOf(_b.hass, "template") or [] for _d, _es in _s if _d not in __templateDomainKeys__ for _e in _es]
__defaultEntityIds__ = [_e.default_entity_id for _b in __renderPackageBackendInstances__ for _s in domainOf(_b.hass, "template") or [] for _d, _es in _s if _d not in __templateDomainKeys__ for _e in _es]
__objectIds__ = {
    _d: [_k for _b in __renderPackageBackendInstances__ for _k in domainOf(_b.hass, _d) or {}]
    for _d in __objectIdDomains__
}
assert not duplicated(__packageNames__), "duplicate package names: ${duplicated(__packageNames__)}"
assert not duplicated(__automationIds__), "duplicate automation ids: ${duplicated(__automationIds__)}"
# HA derives an automation's entity id from its alias when it first registers
# the automation, and appends `_2` on a clash, so equal slugified aliases give
# unpredictable entity ids.
__automationAliasSlugs__ = [common.slugify(_a.alias) for _b in __renderPackageBackendInstances__ for _a in domainOf(_b.hass, "automation") or []]
assert not duplicated(__automationAliasSlugs__), "automation aliases must slugify uniquely across packages (they become entity ids): ${duplicated(__automationAliasSlugs__)}"
assert not duplicated(__templateUniqueIds__), "duplicate template unique_ids within one domain (<domain>:<unique_id>): ${duplicated(__templateUniqueIds__)}"
assert not duplicated(__defaultEntityIds__), "duplicate template default_entity_ids: ${duplicated(__defaultEntityIds__)}"
__objectIdDuplicates__ = {_d: duplicated(_ids) for _d, _ids in __objectIds__ if duplicated(_ids)}
assert not __objectIdDuplicates__, "duplicate object ids across packages: ${__objectIdDuplicates__}"

# Encode every file without `ignore_none`, so `to: null` and
# `default_config: null` survive. Collect the `!secret` names before `untag`
# removes the sentinels, then untag.
__encoded__ = {
    "configuration.yaml" = yaml.encode(__renderRootBackendInstance__.hass, ignore_private=True)
    **{"{}/{}.yaml".format(__root__.packagesDir, _b.config.name): yaml.encode(_b.hass, ignore_private=True) for _b in __renderPackageBackendInstances__}
}
# yaml.encode leaves the strings `=` and `<<` unquoted, and HA's YAML 1.1
# loader reads them as the `value` and `merge` tags, so the whole file fails to
# load. The pattern matches either string as a bare key, list item, or value. A
# block scalar line that holds only one of them also matches, and the render
# fails on it too.
_BARE_TAG_SCALAR = r"(?m)^ *(?:- )*(?:(?:=|<<):(?: |$)|(?:[^\n]*?: )?(?:=|<<)$)"
__bareTagScalars__ = {_k: [_m.strip() for _m in regex.findall(_v, _BARE_TAG_SCALAR)] for _k, _v in __encoded__ if regex.search(_v, _BARE_TAG_SCALAR)}
assert not __bareTagScalars__, "the strings `=` and `<<` are not allowed as a key or a value, because HA's YAML loader reads them as tags: ${__bareTagScalars__}"

__secretNames__ = sorted({_n = None for _, _v in __encoded__ for _n in tags.secret_names(_v)})

__undeclaredSecrets__ = [_n for _n in __secretNames__ if _n not in __root__.secrets]
assert not __undeclaredSecrets__, "undeclared secrets referenced: ${__undeclaredSecrets__}; declare each in HomeAssistant.secrets with a fake value"

_header = "# Code generated by haconfig; DO NOT EDIT.\n" + ("# Revision: {}\n".format(hmd.context.revision) if hmd.context.revision else "")

# The files that HA writes at runtime, and the files that the host or the HA UI
# owns. A deploy branch rooted at the rendered directory must not track them.
_DEPLOY_GITIGNORE = """\
.storage/
.cloud/
deps/
tts/
backups/
*.db
*.db-shm
*.db-wal
home-assistant.log*
.HA_VERSION
.ha_run.lock
secrets.yaml
automations.yaml
scripts.yaml
scenes.yaml
"""

_secretsExample = yaml.encode({_n = __root__.secrets[_n] for _n in __secretNames__}) if __secretNames__ else "{}\n"

_files = {_k: _header + tags.untag(_v) for _k, _v in __encoded__} | {
    "secrets.example.yaml" = _header + "# Fake values for every !secret this config references. Real values live on the Pi.\n" + _secretsExample
    if __root__.deployGitignore:
        ".gitignore" = _header + _DEPLOY_GITIGNORE
}

manifests.yaml_stream([{path = _k, content = _v} for _k, _v in _files])
