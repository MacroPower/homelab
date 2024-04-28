// jsonnet base/wireguard-site-to-site/main.jsonnet -J vendor

local netPolicy = std.parseYaml(importstr 'network-policy.yaml');
local server = std.parseYaml(importstr 'server.yaml');

netPolicy + server
