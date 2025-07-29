// jsonnet base/external-services/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local services = import 'services.libsonnet';

[ns] + services
