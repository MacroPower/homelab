local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local authentik = std.parseYaml(importstr 'authentik.yaml');

[ns] + secrets + [authentik]
