[package]
name = "external_certs_mgmt"
version = "0.1.0"

[dependencies]
external_certs_base = { path = "../base" }
cluster = { path = "../../../../clusters/mgmt" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
