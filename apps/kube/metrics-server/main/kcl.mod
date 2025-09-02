[package]
name = "kube_metrics_server_main"
version = "0.1.0"

[dependencies]
kube_metrics_server_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
