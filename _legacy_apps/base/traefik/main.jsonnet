local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local dashboard_ingress = import 'dashboard_ingress.libsonnet';

[ns] + secrets + dashboard_ingress
