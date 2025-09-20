[package]
name = "securecodebox_seaweedfs_main"
version = "0.1.0"

[dependencies]
securecodebox_seaweedfs_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
