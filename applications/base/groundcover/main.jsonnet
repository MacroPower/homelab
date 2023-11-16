// jsonnet base/groundcover/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + secrets
