[package]
name = "external_secrets_mgmt"
version = "0.1.0"

[dependencies]
external_secrets_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
