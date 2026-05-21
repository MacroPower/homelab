[package]
name = "ci_shared"
version = "0.1.0"

[dependencies]
ci_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
