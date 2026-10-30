import runtime

test_valid_state = lambda {
    _s = State {
        floors.ground = {name = "Ground Floor", level = 0, aliases = ["Downstairs"]}
        areas.living_room = {name = "Living Room", floor = "ground", labels = ["lights"], temperatureEntity = "sensor.living_room_temperature"}
        labels.lights = {name = "Lights", color = "#FFAA00"}
        labels.critical = {name = "Critical", color = "red"}
        categories.automation.lighting = {name = "Lighting"}
        prune = ["areas", "labels"]
    }
    assert len(_s.areas) == 1
}

test_keys_must_be_slugs = lambda {
    _err = runtime.catch(lambda {
        _k: any = "Living Room"
        State {areas = {"${_k}" = {name = "Living Room"}}}
    })
    assert "got [areas.Living Room]" in _err, "got: ${_err}"
}

test_category_scope_must_be_slug = lambda {
    _err = runtime.catch(lambda {
        _s: any = "My Scope"
        State {categories = {"${_s}" = {lighting = {name = "Lighting"}}}}
    })
    assert "got [categories.My Scope]" in _err, "got: ${_err}"
}

test_prune_needs_managed_collection = lambda {
    _unknown = runtime.catch(lambda {
        _p: any = ["rooms"]
        State {areas = {}, prune = _p}
    })
    _unmanaged = runtime.catch(lambda {
        _p: any = ["floors"]
        State {areas = {}, prune = _p}
    })
    assert "got [rooms]" in _unknown, "got: ${_unknown}"
    assert "got [floors]" in _unmanaged, "got: ${_unmanaged}"
}

test_duplicate_names_ignore_case_and_whitespace = lambda {
    _areas = runtime.catch(lambda {
        _n: any = "living room"
        State {areas = {a = {name = "Living Room"}, b = {name = _n}}}
    })
    _categories = runtime.catch(lambda {
        _n: any = "LIGHTING"
        State {categories.automation = {a = {name = "Lighting"}, b = {name = _n}}}
    })
    assert "areas: livingroom" in _areas, "got: ${_areas}"
    assert "categories.automation: lighting" in _categories, "got: ${_categories}"
}

test_label_color = lambda {
    _err = runtime.catch(lambda {
        _c: any = "#FFF"
        Label {name = "Lights", color = _c}
    })
    assert "color must be #RRGGBB" in _err, "got: ${_err}"
}

test_area_field_checks = lambda {
    _floor = runtime.catch(lambda {
        _f: any = "Ground Floor"
        Area {name = "Hall", floor = _f}
    })
    _labels = runtime.catch(lambda {
        _l: any = ["Lights"]
        Area {name = "Hall", labels = _l}
    })
    _temperature = runtime.catch(lambda {
        _t: any = "climate.hall"
        Area {name = "Hall", temperatureEntity = _t}
    })
    _aliases = runtime.catch(lambda {
        _a: any = [" "]
        Area {name = "Hall", aliases = _a}
    })
    assert "floor must be a floor id" in _floor, "got: ${_floor}"
    assert "labels must be label ids, got [Lights]" in _labels, "got: ${_labels}"
    assert "temperatureEntity must be a sensor entity id" in _temperature, "got: ${_temperature}"
    assert "aliases must not be empty strings" in _aliases, "got: ${_aliases}"
}

test_devices_entities_integrations = lambda {
    _s = State {
        devices.hall_lamp = {match.id = "0123456789abcdef0123456789abcdef", name = "Hall Lamp", area = "hall", labels = ["lights"]}
        devices.bridge = {match.connection = ["mac", "AA:BB:CC:DD:EE:FF"], area = None}
        entities = {
            "light.hall_lamp" = {name = None, icon = "mdi:lamp", hidden = True, categories = {automation = "Lighting"}}
            "sensor.hall_temp" = {match = {platform = "zha", uniqueId = "00:11-1-1026"}, deviceClass = "temperature"}
        }
        integrations.hue = {domain = "hue", entryId = "01JK293EHKSF1ME1VEXT4MCN9P", title = "Hue Bridge"}
        integrations.met = {domain = "met", title = "Home"}
    }
    assert len(_s.devices) == 2 and len(_s.entities) == 2 and len(_s.integrations) == 2
}

test_device_match_needs_exactly_one_field = lambda {
    _none = runtime.catch(lambda {
        _m: any = {}
        Device {match = _m}
    })
    _two = runtime.catch(lambda {
        _m: any = {id = "0123456789abcdef0123456789abcdef", connection = ["mac", "aa"]}
        Device {match = _m}
    })
    _id = runtime.catch(lambda {
        _m: any = {id = "hall"}
        Device {match = _m}
    })
    assert "exactly one of id, identifier, and connection, got []" in _none, "got: ${_none}"
    assert "got [id, connection]" in _two, "got: ${_two}"
    assert "match.id must be a 32-character hex device id" in _id, "got: ${_id}"
}

test_entity_keys_are_entity_ids = lambda {
    _err = runtime.catch(lambda {
        _k: any = "hall_lamp"
        State {entities = {"${_k}" = {name = "Lamp"}}}
    })
    assert "got [entities.hall_lamp]" in _err, "got: ${_err}"
}

test_two_devices_cannot_share_a_match = lambda {
    _err = runtime.catch(lambda {
        _id: any = "0123456789abcdef0123456789abcdef"
        State {devices = {a = {match.id = _id}, b = {match.id = _id}}}
    })
    assert "two devices match the same device id" in _err, "got: ${_err}"
}

test_devices_cannot_be_pruned = lambda {
    _err = runtime.catch(lambda {
        _p: any = ["devices"]
        State {devices = {}, prune = _p}
    })
    assert "got [devices]" in _err, "got: ${_err}"
}

test_integration_needs_entry_id_or_title = lambda {
    _err = runtime.catch(lambda {
        _d: any = "hue"
        Integration {domain = _d}
    })
    assert "needs entryId or title" in _err, "got: ${_err}"
}

test_apps_and_hacs = lambda {
    _s = State {
        apps.core_mosquitto = {version = "6.5.1", options = {logins = [], require_certificate = False}, boot = "auto", network = {"1883/tcp" = 1883, "8883/tcp" = None}, started = True}
        appRepositories = ["https://github.com/esphome/home-assistant-addon"]
        hacs = {"hacs/integration" = {category = "integration", version = "2.0.5"}}
        prune = ["apps", "hacs"]
    }
    assert len(_s.apps) == 1 and len(_s.hacs) == 1
}

test_app_network_checks = lambda {
    _ok = App {network = {"22" = 22, "53/udp" = None}}
    _err = runtime.catch(lambda {
        _n: any = {"22/sctp" = 22}
        App {network = _n}
    })
    assert len(_ok.network) == 2
    assert "network keys must look like `22/tcp` or `22`" in _err, "got: ${_err}"
}

test_app_none_fields = lambda {
    _option = runtime.catch(lambda {
        _v: any = None
        App {options = {log_level = _v}}
    })
    _field = runtime.catch(lambda {
        _v: any = None
        App {started = _v}
    })
    _slug = State {apps = {"local_My.App" = {}}}
    assert "set the default value instead" in _option, "got: ${_option}"
    assert "[started] must not be None" in _field, "got: ${_field}"
    assert len(_slug.apps) == 1
}

test_settings_none_fields = lambda {
    _entity = runtime.catch(lambda {
        _v: any = None
        Entity {hidden = _v}
    })
    _category = runtime.catch(lambda {
        _v: any = None
        Entity {categories = {automation = _v}}
    })
    _integration = runtime.catch(lambda {
        _v: any = None
        Integration {domain = "hue", entryId = "abc", title = _v}
    })
    _device = runtime.catch(lambda {
        _v: any = None
        Device {match.id = "00000000000000000000000000000001", disabled = _v}
    })
    assert "[hidden] must be True or False" in _entity, "got: ${_entity}"
    assert "got None for [automation]" in _category, "got: ${_category}"
    assert "[title] must not be None" in _integration, "got: ${_integration}"
    assert "disabled must be True or False" in _device, "got: ${_device}"
}

test_hacs_keys_and_categories = lambda {
    _key = runtime.catch(lambda {
        _k: any = "integration"
        State {hacs = {"${_k}" = {category = "integration", version = "1"}}}
    })
    _category = runtime.catch(lambda {
        _c: any = "lovelace"
        HacsRepository {category = _c, version = "1"}
    })
    _case = runtime.catch(lambda {
        _k: any = "HACS/Integration"
        State {hacs = {"hacs/integration" = {category = "integration", version = "1"}, "${_k}" = {category = "integration", version = "1"}}}
    })
    _owner = runtime.catch(lambda {
        _k: any = "my_org/card"
        State {hacs = {"${_k}" = {category = "plugin", version = "1"}}}
    })
    assert "got [hacs.integration]" in _key, "got: ${_key}"
    assert "my_org/card" in _owner, "got: ${_owner}"
    assert "category must be one of" in _category, "got: ${_category}"
    assert "ignore case" in _case, "got: ${_case}"
}

test_http_checks = lambda {
    _ok = Http {serverPort = 443, sslCertificate = "/ssl/fullchain.pem", sslKey = "/ssl/privkey.pem", corsAllowedOrigins = ["https://cast.home-assistant.io"]}
    _proxy = runtime.catch(lambda {
        _f: any = True
        Http {useXForwardedFor = _f}
    })
    _combined = Http {sslCertificate = "/ssl/combined.pem"}
    _keyOnly = Http {sslKey = "/ssl/privkey.pem"}
    _port = runtime.catch(lambda {
        _p: any = 70000
        Http {serverPort = _p}
    })
    assert _ok.serverPort == 443
    assert "needs at least one trusted proxy" in _proxy, "got: ${_proxy}"
    assert _combined.sslCertificate == "/ssl/combined.pem"
    assert _keyOnly.sslKey == "/ssl/privkey.pem"
    assert "between 1 and 65535" in _port, "got: ${_port}"
}

test_category_names_compare_by_case_only = lambda {
    _s = State {categories.automation = {a = {name = "My Lights"}, b = {name = "MyLights"}}}
    _dup = runtime.catch(lambda {
        _n: any = "my lights"
        State {categories.automation = {a = {name = "My Lights"}, b = {name = _n}}}
    })
    _repos = runtime.catch(lambda {
        _r: any = None
        State {appRepositories = _r}
    })
    assert len(_s.categories.automation) == 2
    assert "categories.automation: my lights" in _dup, "got: ${_dup}"
    assert "appRepositories must be a list" in _repos, "got: ${_repos}"
}
