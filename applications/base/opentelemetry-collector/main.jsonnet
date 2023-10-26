// jsonnet base/opentelemetry-collector/main.jsonnet -J vendor

local collector = std.parseYaml(importstr 'collector.yaml');

collector
