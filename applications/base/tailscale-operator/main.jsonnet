// jsonnet base/tailscale-operator/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local magicDNS = std.parseYaml(importstr 'magic-dns.yaml');

[ns] + secrets + magicDNS
