[package]
name = "kube_metrics_server_base"
version = "0.1.0"

[dependencies]
kube = { path = "../../_tenant/shared" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
