local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + [secrets]
