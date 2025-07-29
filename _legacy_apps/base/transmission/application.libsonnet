local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='transmission',
  path='applications/base/transmission',
  namespace=ns.metadata.name,
)
