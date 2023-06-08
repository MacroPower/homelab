local ingress = import 'ingress.libsonnet';
local config = std.parseYaml(importstr 'config.yaml');
local config_secrets = std.parseYaml(importstr 'config-secrets.yaml');

ingress +
[config] +
[config_secrets]
