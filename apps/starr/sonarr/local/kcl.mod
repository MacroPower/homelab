[package]
name = "starr_sonarr_local"
version = "0.1.0"

[dependencies]
starr_sonarr_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
