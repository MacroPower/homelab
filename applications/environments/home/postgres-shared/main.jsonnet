// jsonnet base/postgres-shared/main.jsonnet -J vendor

local base = import '../../../base/postgres-shared/main.jsonnet';
local cluster = std.parseYaml(importstr 'cluster.yaml');
local offloading = std.parseYaml(importstr 'offloading.yaml');

base + cluster + offloading
