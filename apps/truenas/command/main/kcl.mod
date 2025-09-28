[package]
name = "truenas_command_main"
version = "0.1.0"

[dependencies]
truenas_command_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
