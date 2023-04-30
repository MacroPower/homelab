local ns = import '../../../base/linkerd-multicluster/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='linkerd-multicluster-hcloud',
  path='applications/environments/home/linkerd-multicluster-hcloud',
  namespace=ns.metadata.name,
)
