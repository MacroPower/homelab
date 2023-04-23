local base = import '../../../base/metallb/main.libsonnet';
local config = std.parseYaml(importstr 'config.yaml');

base + config
