local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-secrets',
  path='applications/base/external-secrets',
  namespace=ns.metadata.name,
).withChart(
  name='external-secrets',
  repoURL='https://charts.external-secrets.io',
  targetRevision='0.12.1',
  releaseName='external-secrets',
  values='values.yaml'
)
