[package]
name = "o11y_loki_main"
version = "0.1.0"

[dependencies]
o11y_loki_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
