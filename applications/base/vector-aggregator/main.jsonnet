// jsonnet base/vector-aggregator/main.jsonnet -J vendor

local ingressPfsense = std.parseYaml(importstr 'ingress-pfsense.yaml');

ingressPfsense
