// jsonnet base/owncloud/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local auth = std.parseYaml(importstr 'auth.yaml');

[ns] + auth
