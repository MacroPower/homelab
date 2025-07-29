// jsonnet base/postgres-shared/main.jsonnet -J vendor

local ns = import '../../../base/postgres-shared/namespace.libsonnet';
local providerSecretSa = std.parseYaml(importstr '../../../base/postgres-shared/provider-secret-sa.yaml');
local providerSecret = std.parseYaml(importstr '../../../base/postgres-shared/provider-secret.yaml');
local provider = std.parseYaml(importstr '../../../base/postgres-shared/provider.yaml');

local cluster = std.parseYaml(importstr 'cluster.yaml');

[ns] +
providerSecretSa +
providerSecret +
provider +
cluster
