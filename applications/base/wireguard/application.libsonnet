local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='wireguard',
  path='applications/base/wireguard',
  namespace=ns.metadata.name,
)
