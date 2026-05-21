[package]
name = "ci_github_runners_main"
version = "0.1.0"

[dependencies]
ci_github_runners_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
