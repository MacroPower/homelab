local base = import '../../../base/authentik/main.jsonnet';

local cert = std.parseYaml(importstr 'cert.yaml');

base + cert
