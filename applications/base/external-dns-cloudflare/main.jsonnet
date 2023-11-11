// jsonnet base/external-dns-cloudflare/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local crd = std.parseYaml(importstr 'crd.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + crd + secrets
