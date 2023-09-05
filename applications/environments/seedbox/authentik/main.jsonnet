local base = import '../../../base/authentik/main.jsonnet';
local claims = std.parseYaml(importstr 'claims.yaml');

base + claims
