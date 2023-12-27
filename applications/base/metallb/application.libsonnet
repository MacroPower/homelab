local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='metallb',
  path='applications/base/metallb',
  namespace=ns.metadata.name,
).withChart(
  name='metallb',
  repoURL='https://metallb.github.io/metallb',
  targetRevision='0.13.12',
  releaseName='metallb',
  values='values.yaml'
)
