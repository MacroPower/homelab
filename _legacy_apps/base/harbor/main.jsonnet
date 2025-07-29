// jsonnet base/harbor/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local database = import 'database/main.libsonnet';
local bucket = std.parseYaml(importstr 'bucket.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');
local redisDragonfly = std.parseYaml(importstr 'redis-dragonfly.yaml');

[ns] + database + bucket + secrets + redisDragonfly
