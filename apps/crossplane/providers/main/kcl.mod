[package]
name = "crossplane_providers_main"
version = "0.1.0"

[dependencies]
crossplane_providers_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
