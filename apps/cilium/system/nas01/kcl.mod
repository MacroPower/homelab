[package]
name = "cilium_system_nas01"
version = "0.1.0"

[dependencies]
cilium_system_base = { path = "../base" }
cluster = { path = "../../../../clusters/nas01" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
