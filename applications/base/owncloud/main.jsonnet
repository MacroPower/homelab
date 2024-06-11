// jsonnet base/owncloud/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local uuids = std.parseYaml(importstr 'uuids.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + uuids + secrets
