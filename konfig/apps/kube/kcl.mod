[package]
name = "kube"
version = "0.0.1"

[dependencies]
konfig = { path = "../../../konfig" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
