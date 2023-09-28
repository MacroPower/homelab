// jsonnet base/wakatime-exporter/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = import 'secrets.libsonnet';

[ns] + secrets
