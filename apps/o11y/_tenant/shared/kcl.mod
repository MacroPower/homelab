[package]
name = "o11y_shared"
version = "0.1.0"

[dependencies]
o11y_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
