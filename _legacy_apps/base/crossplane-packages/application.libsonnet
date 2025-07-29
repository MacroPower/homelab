local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='crossplane-packages',
  path='applications/base/crossplane-packages',
  namespace=ns.metadata.name,
)
