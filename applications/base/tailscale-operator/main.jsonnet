// jsonnet base/tailscale-operator/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local magicDNS = std.parseYaml(importstr 'magic-dns.yaml');
local roles = std.parseYaml(importstr 'roles.yaml');

[ns] + secrets + magicDNS + roles
