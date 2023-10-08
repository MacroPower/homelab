// jsonnet base/vector-aggregator/main.jsonnet -J vendor

local dns = std.parseYaml(importstr 'dns.yaml');
local ingressPfsense = std.parseYaml(importstr 'ingress-pfsense.yaml');

dns + ingressPfsense
