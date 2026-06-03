[package]
name = "crossplane_system_local"
version = "0.1.0"

[dependencies]
crossplane_system_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
