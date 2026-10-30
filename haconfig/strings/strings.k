import regex

# Copyright 2024 The KCL Authors.
# Modifications copyright 2025 Jacob Colvin.
# Licensed under the Apache License, Version 2.0.
# https://github.com/kcl-lang/modules/tree/main/outdent
#
# `dedent` is vendored from konfig/strings/dedent.k, so haconfig has no
# dependencies. Its locals carry the `_dd` prefix, because a name inside a
# lambda's comprehension resolves to a same-named attribute of the calling
# schema first.

dedent = lambda text: str -> str {
    """
    `dedent` removes common leading whitespace from multi-line strings, and
    trims leading and trailing blank lines.
    """
    _ddLines = regex.split(text, "\r\n|\n")
    _ddLead = lambda line: str -> str {
        _ddWs = regex.findall(line, "^\s+")
        _ddWs[0] if _ddWs else ""
    }
    _ddIndents = [len(_ddLead(_ddL)) for _ddL in _ddLines if _ddL.strip()]
    _ddMin = min([""] | _ddIndents)
    _ddOut = "\n".join([_ddL[_ddMin::] if _ddL.strip() else _ddL for _ddL in _ddLines])
    regex.replace(_ddOut, r'^\s*\n|\n\s*$', '')
}

jinja = lambda text: str -> str {
    """
    `jinja` dedents a multi-line Jinja template and strips trailing spaces and
    tabs from every line. `yaml.encode` then writes the template as a `|-` block
    scalar. A line that ends in a space makes the encoder fall back to a
    double-quoted string. Pass every multi-line template through `jinja`.
    """
    regex.replace(dedent(text), r"[ \t]+\n", "\n").rstrip()
}
