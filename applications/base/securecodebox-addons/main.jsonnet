// jsonnet base/securecodebox-addons/main.jsonnet -J vendor

local secrets = std.parseYaml(importstr 'secrets.yaml');

secrets
