[package]
name = "kube_spegel_main"
version = "0.1.0"

[dependencies]
kube_spegel_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
