// jsonnet base/tetragon/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local policies = import 'policies/main.libsonnet';

[ns] + policies
