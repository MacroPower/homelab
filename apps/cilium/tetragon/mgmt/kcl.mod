[package]
name = "cilium_tetragon_mgmt"
version = "0.1.0"

[dependencies]
cilium_tetragon_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
