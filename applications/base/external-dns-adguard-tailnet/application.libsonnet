local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-dns-tailnet',
  path='applications/base/external-dns-adguard-tailnet',
  namespace=ns.metadata.name,
).withChart(
  name='external-dns',
  repoURL='https://kubernetes-sigs.github.io/external-dns',
  targetRevision='1.13.1',
  releaseName='external-dns-tailnet',
  values='values.yaml'
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.2.0',
  releaseName='external-dns-provider-adguard-tailnet',
  values='values-provider-adguard.yaml'
)
