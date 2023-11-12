// jsonnet base/chronyd/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local config = import 'config/main.libsonnet';

[ns] + config
