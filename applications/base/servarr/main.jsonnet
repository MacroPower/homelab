// jsonnet base/servarr/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local offloading = std.parseYaml(importstr 'offloading.yaml');

[ns] + offloading
