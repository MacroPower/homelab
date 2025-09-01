[package]
name = "o11y_grafana_main"
version = "0.1.0"

[dependencies]
o11y_grafana_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
