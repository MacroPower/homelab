local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='excoredns',
  path='applications/base/excoredns',
  namespace='kube-system',
).withChart(
  name='k8s-gateway',
  repoURL='https://ori-edge.github.io/k8s_gateway',
  targetRevision='2.4.0',
  releaseName='excoredns',
  values='values.yaml'
)
