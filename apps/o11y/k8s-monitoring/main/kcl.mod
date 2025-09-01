[package]
name = "o11y_k8s_monitoring_main"
version = "0.1.0"

[dependencies]
o11y_k8s_monitoring_base = { path = "../base" }
cluster = { path = "../../../../clusters/main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
