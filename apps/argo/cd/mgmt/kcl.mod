[package]
name = "argo_cd_mgmt"
version = "0.1.0"

[dependencies]
argo_cd_base = { path = "../base" }
cluster = { path = "../../../../clusters/mgmt" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
