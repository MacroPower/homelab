local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-dns',
  path='applications/base/external-dns-adguard',
  namespace=ns.metadata.name,
).withChart(
  name='external-dns',
  repoURL='https://kubernetes-sigs.github.io/external-dns',
  targetRevision='1.14.3',
  releaseName='external-dns',
  values='values.yaml'
)
