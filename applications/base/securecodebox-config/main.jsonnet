// jsonnet base/securecodebox-config/main.jsonnet -J vendor

local configSA = std.parseYaml(importstr 'config-sa.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');
local scans = import 'scans/main.libsonnet';

configSA + secrets + scans
