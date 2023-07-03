local cert = import 'cert.libsonnet';
local ingress = import 'ingress.libsonnet';
local issuer = std.parseYaml(importstr 'issuer.yaml');
local middleware = std.parseYaml(importstr 'middleware.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');

cert +
ingress +
issuer +
[middleware] +
secrets
