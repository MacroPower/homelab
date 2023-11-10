// jsonnet base/tailscale-exit/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local rbac = std.parseYaml(importstr 'rbac.yaml');
local networkPolicy = std.parseYaml(importstr 'network-policy.yaml');

[ns] + secrets + rbac + networkPolicy
