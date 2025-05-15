[package]
name = "bootstrap_core_nas01"
version = "0.1.0"

[dependencies]
bootstrap = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
