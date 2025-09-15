[package]
name = "public"
version = "0.1.0"

[dependencies]
public_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
