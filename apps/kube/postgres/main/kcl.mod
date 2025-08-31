[package]
name = "kube_postgres_main"
version = "0.1.0"

[dependencies]
kube_postgres_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
