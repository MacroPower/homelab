[package]
name = "dragonfly_operator_mgmt"
version = "0.1.0"

[dependencies]
dragonfly_operator_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
