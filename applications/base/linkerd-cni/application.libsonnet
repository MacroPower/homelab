local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='linkerd2-cni',
  path='applications/base/linkerd2-cni',
  namespace=ns.metadata.name,
).withChart(
  name='linkerd2-cni',
  repoURL='https://helm.linkerd.io/edge',
  targetRevision='30.7.1-edge',
  releaseName='linkerd-cni',
  values='values.yaml'
)
