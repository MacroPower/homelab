local ns = import '../../../base/linkerd-multicluster/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='linkerd-multicluster-seedbox',
  path='applications/environments/home/linkerd-multicluster-seedbox',
  namespace=ns.metadata.name,
)
