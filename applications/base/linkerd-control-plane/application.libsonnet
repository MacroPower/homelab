local app = import '../../lib/app.libsonnet';

app.new(
  name='linkerd-control-plane',
  path='applications/base/linkerd-control-plane',
  namespace='linkerd',
).withChart(
  name='linkerd-control-plane',
  repoURL='https://helm.linkerd.io/edge',
  targetRevision='1.11.4-edge',
  releaseName='linkerd-control-plane',
  values='values.yaml'
)
