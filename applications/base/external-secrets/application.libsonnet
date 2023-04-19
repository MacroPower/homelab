local app = import '../../lib/app.libsonnet';

app.new(
  name='external-secrets',
  path='applications/base/external-secrets',
  namespace='kube-system',
).withChart(
  name='external-secrets',
  repoURL='https://charts.external-secrets.io',
  targetRevision='0.6.0',
  releaseName='external-secrets',
  values='values.yaml'
)
