// jsonnet base/external-secrets/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local dopplerStore = std.parseYaml(importstr 'doppler-store.yaml');
local serviceMonitor = std.parseYaml(importstr 'service-monitor.yaml');

[ns] + dopplerStore + serviceMonitor
