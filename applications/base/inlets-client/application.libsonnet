local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='inlets-client',
  path='applications/base/inlets-client',
  namespace=ns.metadata.name,
)
