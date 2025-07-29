// jsonnet base/ocis-nack/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local streams = std.parseYaml(importstr 'streams.yaml');

[ns] + streams
