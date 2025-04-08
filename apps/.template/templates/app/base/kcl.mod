[package]
name = "{{.TenantName}}_{{.AppName}}_base"
version = "0.1.0"

[dependencies]
{{.TenantName}} = { path = "../../_tenant/shared" }
