local ns = import 'namespace.libsonnet';
local collector = std.parseYaml(importstr 'collector.yaml');
local sa = std.parseYaml(importstr 'sa.yaml');

[ns] + [collector] + [sa]
