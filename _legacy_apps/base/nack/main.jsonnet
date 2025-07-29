// jsonnet base/nack/main.jsonnet -J vendor

local crds = std.parseYaml(importstr 'crds.yaml');

crds
