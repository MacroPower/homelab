[package]
name = "ci_dagger_engine_local"
version = "0.1.0"

[dependencies]
ci_dagger_engine_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
