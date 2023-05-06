local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='linkerd-crds',
  path='applications/base/linkerd',
  namespace=ns.metadata.name,
).withChart(
  name='linkerd-crds',
  repoURL='https://helm.linkerd.io/edge',
  targetRevision='1.7.0-edge',
  releaseName='linkerd-crds',
)
