local ns = import '../../../base/metallb/namespace.libsonnet';
local config = std.parseYaml(importstr 'config.yaml');

[ns] + config
