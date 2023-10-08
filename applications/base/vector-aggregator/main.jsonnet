// jsonnet base/vector-aggregator/main.jsonnet -J vendor

local dns = std.parseYaml(importstr 'dns.yaml');
local ingress = std.parseYaml(importstr 'ingress.yaml');

dns + ingress
