// jsonnet base/argocd/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local auth = std.parseYaml(importstr 'auth.yaml');
local ingress = import 'ingress.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local redisDragonfly = std.parseYaml(importstr 'redis-dragonfly.yaml');
local serviceMonitor = std.parseYaml(importstr 'service-monitor.yaml');

auth + ingress + secrets + redisDragonfly + serviceMonitor
