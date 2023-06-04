local ns = import 'namespace.libsonnet';
local pfsense = std.parseYaml(importstr 'pfsense.yaml');

[ns] + pfsense
