// jsonnet base/crossplane-packages/main.jsonnet -J vendor

[]
+ std.parseYaml(importstr 'authentik.yaml')
+ std.parseYaml(importstr 'sql.yaml')
