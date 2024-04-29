local ingress = import 'ingress.libsonnet';
local middleware = std.parseYaml(importstr 'middleware.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');

ingress +
[middleware] +
secrets
