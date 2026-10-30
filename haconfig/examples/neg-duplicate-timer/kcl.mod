[package]
name = "neg_duplicate_timer"
version = "0.1.0"

[dependencies]
hallway = { path = "../hallway" }

[profile]
entries = ["main.k", "${haconfig:KCL_MOD}/models/render/render.k"]
