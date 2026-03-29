[package]
name = "public_meshcentral_main"
version = "0.1.0"

[dependencies]
public_meshcentral_base = { path = "../base" }
cluster = { path = "../../../../clusters/main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
