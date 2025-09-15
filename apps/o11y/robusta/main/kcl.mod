[package]
name = "o11y_robusta_main"
version = "0.1.0"

[dependencies]
o11y_robusta_base = { path = "../base" }
cluster = { path = "../../../../clusters/main" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
