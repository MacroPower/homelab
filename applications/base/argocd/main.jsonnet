// jsonnet base/argocd/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ingress = import 'ingress.libsonnet';
local serviceMonitor = std.parseYaml(importstr 'service-monitor.yaml');

ingress + serviceMonitor
