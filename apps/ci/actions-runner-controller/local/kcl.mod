[package]
name = "ci_actions_runner_controller_local"
version = "0.1.0"

[dependencies]
ci_actions_runner_controller_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
