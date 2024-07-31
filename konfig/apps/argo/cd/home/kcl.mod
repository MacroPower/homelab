[package]
name = "clusters-home"
version = "0.0.1"

[dependencies]
konfig = { path = "../../../../../konfig" }
tenant = { path = "../../" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
