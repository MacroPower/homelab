// jsonnet base/external-dns-local/main.jsonnet -J vendor

local crd = std.parseYaml(importstr 'crd.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');

crd + secrets
