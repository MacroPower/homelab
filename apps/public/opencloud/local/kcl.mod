[package]
name = "public_opencloud_local"
version = "0.1.0"

[dependencies]
public_opencloud_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
