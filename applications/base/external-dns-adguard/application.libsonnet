local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-dns',
  path='applications/base/external-dns-adguard',
  namespace=ns.metadata.name,
).withChart(
  name='external-dns',
  repoURL='https://kubernetes-sigs.github.io/external-dns',
  targetRevision='1.13.1',
  releaseName='external-dns',
  values='values.yaml'
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.2.0',
  releaseName='external-dns-provider-adguard',
  values='values-provider-adguard.yaml'
)
