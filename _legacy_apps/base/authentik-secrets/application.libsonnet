local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='authentik-secrets',
  path='applications/base/authentik-secrets',
  namespace=ns.metadata.name,
)
