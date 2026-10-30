import json
import yaml
import runtime

test_secret_untag = lambda {
    _out = untag(yaml.encode({password = secret("mqtt_pw")}))
    assert _out == "password: !secret mqtt_pw\n", "got: ${_out}"
}

test_literal_bang_stays_quoted = lambda {
    _out = untag(yaml.encode({v = "!secret not_a_tag"}))
    assert _out == "v: '!secret not_a_tag'\n", "got: ${_out}"
}

test_list_item = lambda {
    _out = untag(yaml.encode({l = [include("a.yaml")]}))
    assert _out == "l:\n- !include a.yaml\n", "got: ${_out}"
}

test_include_dir_and_env_var = lambda {
    _out = untag(yaml.encode({
        p = include_dir_named("packages")
        e = env_var("TZ", "UTC")
        h = env_var("HOME")
    }))
    assert _out == "p: !include_dir_named packages\ne: !env_var TZ UTC\nh: !env_var HOME\n", "got: ${_out}"
}

test_secret_names = lambda {
    _enc = yaml.encode({a = secret("b_key"), c = [secret("a_key"), secret("b_key")]})
    _names = secret_names(_enc)
    assert _names == ["a_key", "b_key"], "got: ${_names}"
}

test_quote_in_arg_rejected = lambda {
    _err = runtime.catch(lambda {
        _n: any = 'it"s'
        secret(_n)
    })
    assert "must not be empty" in _err, "got: ${_err}"
}

test_empty_arg_rejected = lambda {
    _err = runtime.catch(lambda {
        _n: any = ""
        include(_n)
    })
    assert "`!include` argument must not be empty" in _err, "got: ${_err}"
}

test_env_var_empty_name_rejected = lambda {
    _err = runtime.catch(lambda {
        _n: any = ""
        env_var(_n, "http://x:8123")
    })
    assert "`!env_var` name must be one word" in _err, "got: ${_err}"
}

test_env_var_name_with_space_rejected = lambda {
    _err = runtime.catch(lambda {
        _n: any = "A B"
        env_var(_n)
    })
    assert "`!env_var` name must be one word" in _err, "got: ${_err}"
}

# A schema with a `text` attribute must not shadow the lambda's parameter.
schema _SecretNamesCaller:
    text: str = "nothing here"
    names: [str] = secret_names('"\\0!secret real_name"')

test_secret_names_from_schema_with_text_attribute = lambda {
    _names = _SecretNamesCaller {}.names
    assert _names == ["real_name"], "got: ${_names}"
}

test_json_untag_keeps_a_secret_string = lambda {
    _j = json.encode({password = secret("mqtt_password"), plain = "!secret not_a_tag"})
    assert json_tags(_j) == ["!secret mqtt_password"], "got: ${json_tags(_j)}"
    assert json_untag(_j) == '{"password": "!secret mqtt_password", "plain": "!secret not_a_tag"}', "got: ${json_untag(_j)}"
    assert json_tags(json.encode({p = include("x.yaml")})) == ["!include x.yaml"]
}
