local ns = import 'namespace.libsonnet';
local database = import 'database/main.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + database + secrets
