[package]
name = "kube_volsync_main"
version = "0.1.0"

[dependencies]
kube_volsync_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
