[package]
name = "public_rustdesk_local"
version = "0.1.0"

[dependencies]
public_rustdesk_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
