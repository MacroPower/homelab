// jsonnet base/external-dns-adguard/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local crd = std.parseYaml(importstr 'crd.yaml');

[ns] + crd
