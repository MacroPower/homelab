[package]
name = "o11y_wakatime_exporter_main"
version = "0.1.0"

[dependencies]
o11y_wakatime_exporter_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
