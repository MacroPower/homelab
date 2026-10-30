import yaml

test_dedent = lambda {
    _t = dedent("""\
        a
          b
    """)
    assert _t == "a\n  b", "got: ${_t}"
}

test_jinja_block_style = lambda {
    _t = jinja("""\
        {% set a = 1 %}
        {{ a }}
    """)
    _got = yaml.encode({state = _t})
    assert _got == "state: |-\n  {% set a = 1 %}\n  {{ a }}\n", "got: ${_got}"
}
