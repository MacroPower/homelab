local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='linkerd-multicluster',
  path='applications/base/linkerd-multicluster',
  namespace=ns.metadata.name,
).withChart(
  name='linkerd-multicluster',
  repoURL='https://helm.linkerd.io/edge',
  targetRevision='30.5.1-edge',
  releaseName='linkerd-multicluster',
  values='values.yaml'
)
