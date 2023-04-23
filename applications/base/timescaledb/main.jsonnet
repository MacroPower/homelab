local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local backup = std.parseYaml(importstr 'backup.yaml');
local crossplane = std.parseYaml(importstr 'crossplane.yaml');
local init = std.parseYaml(importstr 'init.yaml');

[ns] +
secrets +
backup +
[crossplane] +
[init]
