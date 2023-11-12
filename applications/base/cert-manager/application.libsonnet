local app = import '../../lib/app.libsonnet';

app.new(
  name='cert-manager',
  path='applications/base/cert-manager',
  namespace='kube-system',
).withChart(
  name='cert-manager',
  repoURL='https://charts.jetstack.io',
  targetRevision='v1.13.2',
  releaseName='cert-manager',
  values='values.yaml'
)
