local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='cilium',
  path='applications/base/cilium',
  namespace='cilium',
)
