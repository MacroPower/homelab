[package]
name = "securecodebox_system_local"
version = "0.1.0"

[dependencies]
securecodebox_system_main = { path = "../main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
