local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-services',
  path='applications/base/external-services',
  namespace=ns.metadata.name,
)
