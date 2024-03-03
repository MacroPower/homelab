// jsonnet base/postgres-shared/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local cluster = std.parseYaml(importstr 'cluster.yaml');
local providerSecretSa = std.parseYaml(importstr 'provider-secret-sa.yaml');
local providerSecret = std.parseYaml(importstr 'provider-secret.yaml');
local provider = std.parseYaml(importstr 'provider.yaml');

[ns] +
cluster +
providerSecretSa +
providerSecret +
provider
