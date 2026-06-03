[package]
name = "starr_qbt_tv_local"
version = "0.1.0"

[dependencies]
starr_qbt_tv_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
