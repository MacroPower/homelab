[package]
name = "argo_tenant"
version = "0.1.0"

[dependencies]
konfig = { path = "../../../konfig" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
