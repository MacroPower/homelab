[package]
name = "kube_dragonfly_mgmt"
version = "0.1.0"

[dependencies]
kube_dragonfly_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
