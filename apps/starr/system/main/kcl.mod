[package]
name = "starr_system_main"
version = "0.1.0"

[dependencies]
starr_system_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
