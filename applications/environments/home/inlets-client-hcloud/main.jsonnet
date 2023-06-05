local ns = import '../../../base/inlets-client/namespace.libsonnet';
local secrets = std.parseYaml(importstr '../../../base/inlets-client/secrets.yaml');

ns +
secrets
