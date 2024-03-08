// jsonnet base/authentik/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ns = import 'namespace.libsonnet';
local database = import 'database/main.libsonnet';
local ingress = import 'ingress.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local middleware = std.parseYaml(importstr 'middleware.yaml');
local config = import 'config/main.libsonnet';

[ns] + database + ingress + secrets + [middleware] + config
