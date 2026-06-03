[package]
name = "starr_qbt_movies_local"
version = "0.1.0"

[dependencies]
starr_qbt_movies_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
