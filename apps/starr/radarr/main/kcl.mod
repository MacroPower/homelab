[package]
name = "starr_radarr_main"
version = "0.1.0"

[dependencies]
starr_radarr_base = { path = "../base" }
cluster = { path = "../../../../clusters/main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
