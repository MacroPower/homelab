// jsonnet base/authentik-secrets/main.jsonnet -J vendor

local middleware = std.parseYaml(importstr 'middleware.yaml');
local rbac = std.parseYaml(importstr 'rbac.yaml');

middleware + rbac
