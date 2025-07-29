local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='vector',
  path='applications/base/vector',
  namespace=ns.metadata.name,
)
