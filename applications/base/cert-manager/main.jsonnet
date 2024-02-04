// jsonnet base/cert-manager/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local issuer = std.parseYaml(importstr 'issuer.yaml');

[ns] + secrets + issuer
