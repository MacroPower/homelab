local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-dns',
  path='applications/base/external-dns-adguard',
  namespace=ns.metadata.name,
)
