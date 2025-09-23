[package]
name = "public_opencloud_main"
version = "0.1.0"

[dependencies]
public_opencloud_base = { path = "../base" }
cluster = { path = "../../../../clusters/main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
