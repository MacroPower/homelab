[package]
name = "external_certs_main"
version = "0.1.0"

[dependencies]
external_certs_base = { path = "../base" }
cluster = { path = "../../../../clusters/main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
