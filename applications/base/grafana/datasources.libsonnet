local ds = std.parseYaml(importstr 'datasources/datasources.yaml');
local ds_secrets = std.parseYaml(importstr 'datasources/datasource-secrets.yaml');

[ds, ds_secrets]
