local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='opentelemetry-collector',
  path='applications/base/opentelemetry-collector',
  namespace=ns.metadata.name,
)
