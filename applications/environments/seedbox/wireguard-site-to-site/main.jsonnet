local base = import '../../../base/wireguard-site-to-site/main.jsonnet';
local peers = std.parseYaml(importstr 'peers.yaml');

base + peers
