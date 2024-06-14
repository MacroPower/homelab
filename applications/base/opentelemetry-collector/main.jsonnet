// jsonnet base/opentelemetry-collector/main.jsonnet -J vendor

local collector = std.parseYaml(importstr 'collector.yaml');
local instrumentation = std.parseYaml(importstr 'instrumentation.yaml');

collector + instrumentation
