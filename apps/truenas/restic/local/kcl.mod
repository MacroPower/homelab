[package]
name = "truenas_restic_local"
version = "0.1.0"

[dependencies]
truenas_restic_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
