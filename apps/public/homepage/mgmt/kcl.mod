[package]
name = "public_homepage_mgmt"
version = "0.1.0"

[dependencies]
public_homepage_base = { path = "../base" }
cluster = { path = "../../../../clusters/mgmt" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
