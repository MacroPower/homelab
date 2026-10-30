import regex

# `yaml.encode` cannot write YAML tags, and it quotes every string that starts
# with `!`. Each builder below therefore returns a sentinel string that starts
# with NUL and `!`. The NUL forces the encoder into double quotes
# (`"\0!secret x"`), and `untag` rewrites the quoted sentinel into a bare tag
# after encoding. A sentinel that never passes `untag` stays visible as
# `"\0!..."`, and the splitter refuses any file that still holds a NUL byte.
#
# A user string that starts with `!secret ` has no NUL, so it stays a quoted
# string.

_TAG = "\x00!"
_ARG = r"^[^\"\\\x00]+$"
# HA splits an `!env_var` argument on whitespace and treats every word after
# the first as the default, so the name itself must be a single word.
_ENV_NAME = r"^[^\s\"\\\x00]+$"

_tag = lambda kind: str, arg: str -> str {
    assert regex.match(arg, _ARG), "`!${kind}` argument must not be empty or contain `\"`, `\\` or NUL, got `${arg}`"
    "${_TAG}${kind} ${arg}"
}

secret = lambda name: str -> str {
    """
    `secret` returns a `!secret <name>` reference, which HA resolves from
    `secrets.yaml`. Declare every name in `HomeAssistant.secrets`.
    """
    _tag("secret", name)
}

include = lambda path: str -> str {
    """
    `include` returns an `!include <path>` reference, relative to the file that
    holds it.
    """
    _tag("include", path)
}

include_dir_named = lambda path: str -> str {
    """
    `include_dir_named` returns an `!include_dir_named <path>` reference, which
    maps each file stem in the directory to the file's content.
    """
    _tag("include_dir_named", path)
}

include_dir_merge_named = lambda path: str -> str {
    """
    `include_dir_merge_named` returns an `!include_dir_merge_named <path>`
    reference, which merges the mappings of every file in the directory.
    """
    _tag("include_dir_merge_named", path)
}

include_dir_list = lambda path: str -> str {
    """
    `include_dir_list` returns an `!include_dir_list <path>` reference, which
    lists the content of each file in the directory.
    """
    _tag("include_dir_list", path)
}

include_dir_merge_list = lambda path: str -> str {
    """
    `include_dir_merge_list` returns an `!include_dir_merge_list <path>`
    reference, which concatenates the lists of every file in the directory.
    """
    _tag("include_dir_merge_list", path)
}

env_var = lambda name: str, default: str = "" -> str {
    """
    `env_var` returns an `!env_var <name> [default]` reference, which HA
    resolves from its process environment. `name` must be one word, without
    whitespace.
    """
    assert regex.match(name, _ENV_NAME), "`!env_var` name must be one word without whitespace, `\"`, `\\` or NUL, got `${name}`"
    _tag("env_var", "${name} ${default}".strip())
}

untag = lambda text: str -> str {
    """
    `untag` rewrites every encoded sentinel `"\0!<kind> <arg>"` in `text` into
    a bare `!<kind> <arg>` tag. Call it on `yaml.encode` output only.
    """
    regex.replace(text, r'"\\0(![a-z_]+ [^"]*)"', "$1")
}

# The parameter and locals carry the `_sn` prefix, because a name inside a
# lambda's comprehension resolves to a same-named attribute of the calling
# schema first.
secret_names = lambda _snText: str -> [str] {
    """
    `secret_names` returns the sorted, de-duplicated secret names that the
    encoded text `_snText` references. Call it before `untag`.
    """
    _snPrefix = '"\\0!secret '
    _snFound = [_snM.removeprefix(_snPrefix).removesuffix('"') for _snM in regex.findall(_snText, r'"\\0!secret [^"]*"')]
    sorted({_snN = None for _snN in _snFound})
}
