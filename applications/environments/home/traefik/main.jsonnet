local ns = import '../../../base/traefik/namespace.libsonnet';
local authentik = std.parseYaml(importstr '../../../base/traefik/authentik.yaml');
local issuer = std.parseYaml(importstr 'issuer.yaml');

[ns] + issuer + [authentik]
