[package]
name = "external_dns_mgmt"
version = "0.1.0"

[dependencies]
external_dns_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
