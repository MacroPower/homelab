// jsonnet base/defectdojo/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local database = import 'database/main.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local redisDragonfly = std.parseYaml(importstr 'redis-dragonfly.yaml');
local ingress = import 'ingress.libsonnet';
local postInstall = import 'post-install/main.libsonnet';

[ns] + database + secrets + redisDragonfly + ingress + postInstall
