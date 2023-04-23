local app = import '../../lib/app.libsonnet';
local ns = import '../jaeger-operator/namespace.libsonnet';

app.new(
  name='jaeger-aio',
  path='applications/base/jaeger-aio',
  namespace=ns.metadata.name,
)
