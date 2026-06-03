[package]
name = "starr_configarr_local"
version = "0.1.0"

[dependencies]
starr_configarr_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
