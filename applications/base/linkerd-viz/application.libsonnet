local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='linkerd-viz',
  path='applications/base/linkerd-viz',
  namespace=ns.metadata.name,
).withChart(
  name='linkerd-viz',
  repoURL='https://helm.linkerd.io/edge',
  targetRevision='30.4.10-edge',
  releaseName='linkerd-viz',
  values='values.yaml'
)
