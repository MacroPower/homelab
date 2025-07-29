// jsonnet base/external-dns-cloudflare/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + secrets
