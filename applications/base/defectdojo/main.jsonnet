// jsonnet base/defectdojo/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local database = import 'database/main.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local ingress = import 'ingress.libsonnet';

[ns] + database + secrets + ingress
