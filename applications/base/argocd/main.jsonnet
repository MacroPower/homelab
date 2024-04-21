// jsonnet base/argocd/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local auth = std.parseYaml(importstr 'auth.yaml');
local ingress = import 'ingress.libsonnet';
local serviceMonitor = std.parseYaml(importstr 'service-monitor.yaml');

auth + ingress + serviceMonitor
