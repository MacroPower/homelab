[package]
name = "neg_alias_clash"
version = "0.1.0"

[dependencies]
hallway = { path = "../hallway" }

[profile]
entries = ["main.k", "${haconfig:KCL_MOD}/models/render/render.k"]
