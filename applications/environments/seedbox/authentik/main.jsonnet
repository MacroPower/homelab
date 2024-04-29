local base = import '../../../base/authentik/main.jsonnet';
local cert = std.parseYaml(importstr 'cert.yaml');
local claims = std.parseYaml(importstr 'claims.yaml');

base + cert + claims
