// jsonnet base/postgres-shared/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local providerSecretSa = std.parseYaml(importstr 'provider-secret-sa.yaml');
local providerSecret = std.parseYaml(importstr 'provider-secret.yaml');
local provider = std.parseYaml(importstr 'provider.yaml');

[ns] +
providerSecretSa +
providerSecret +
provider
