[package]
name = "cilium_shared"
version = "0.1.0"

[dependencies]
cilium_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
