[package]
name = "securecodebox_system_main"
version = "0.1.0"

[dependencies]
securecodebox_system_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
