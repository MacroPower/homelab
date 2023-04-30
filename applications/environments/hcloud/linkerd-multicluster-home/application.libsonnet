local ns = import '../../../base/linkerd-multicluster/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='linkerd-multicluster-home',
  path='applications/environments/hcloud/linkerd-multicluster-home',
  namespace=ns.metadata.name,
)
