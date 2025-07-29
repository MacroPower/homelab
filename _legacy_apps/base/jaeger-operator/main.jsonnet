local ns = import 'namespace.libsonnet';
local rbac = std.parseYaml(importstr 'rbac.yaml');

[ns] + rbac
