// jsonnet base/authentik/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ns = import 'namespace.libsonnet';
local database = import 'database/main.libsonnet';
local ingress = import 'ingress.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local auth = import 'auth/main.libsonnet';
local redisDragonfly = std.parseYaml(importstr 'redis-dragonfly.yaml');

[ns] + database + ingress + secrets + auth + redisDragonfly
