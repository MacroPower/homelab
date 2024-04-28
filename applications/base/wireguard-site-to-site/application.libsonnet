local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='wireguard-site-to-site',
  path='applications/base/wireguard-site-to-site',
  namespace=ns.metadata.name,
)
