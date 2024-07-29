[package]
name = "grafana-home"
version = "0.0.1"

[dependencies]
base = { path = "../base" }
konfig = { path = "../../../../../konfig" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
