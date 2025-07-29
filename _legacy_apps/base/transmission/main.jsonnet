local ns = import 'namespace.libsonnet';
local backup = std.parseYaml(importstr 'backup.yaml');
local claims = std.parseYaml(importstr 'claims.yaml');

[ns] + backup + claims
