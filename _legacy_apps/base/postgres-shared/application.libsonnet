local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='postgres-shared',
  path='applications/base/postgres-shared',
  namespace=ns.metadata.name,
)
