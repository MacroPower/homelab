// jsonnet base/external-dns-local/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local crd = std.parseYaml(importstr 'crd.yaml');

[ns] + crd
