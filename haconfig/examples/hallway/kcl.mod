[package]
name = "hallway"
version = "0.1.0"

[dependencies]
haconfig = { path = "../.." }

[profile]
entries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]
