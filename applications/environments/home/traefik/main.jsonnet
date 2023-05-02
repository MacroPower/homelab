local ns = import '../../../base/traefik/namespace.libsonnet';
local issuer = std.parseYaml(importstr 'issuer.yaml');

[ns] + issuer
