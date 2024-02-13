// jsonnet base/cert-manager/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local issuerSA = std.parseYaml(importstr 'issuer-sa.yaml');
local issuer = std.parseYaml(importstr 'issuer.yaml');

[ns] + secrets + issuerSA + issuer
