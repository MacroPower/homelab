local cert = import 'cert.libsonnet';
local ingress = import 'ingress.libsonnet';
local init_job = std.parseYaml(importstr 'init-job.yaml');
local init_scripts = std.parseYaml(importstr 'init-scripts.yaml');
local issuer = std.parseYaml(importstr 'issuer.yaml');
local middleware = std.parseYaml(importstr 'middleware.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');
local service = std.parseYaml(importstr 'service.yaml');

cert +
ingress +
[init_job] +
[init_scripts] +
issuer +
[middleware] +
secrets +
[service]
