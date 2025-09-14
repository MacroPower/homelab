[package]
name = "kube_reloader_mgmt"
version = "0.1.0"

[dependencies]
kube_reloader_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
