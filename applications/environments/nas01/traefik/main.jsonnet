local dashboard_ingresss = import '../../../base/traefik/dashboard_ingress.libsonnet';
local ns = import '../../../base/traefik/namespace.libsonnet';
local issuer = std.parseYaml(importstr 'issuer.yaml');

[ns] + issuer + dashboard_ingresss
