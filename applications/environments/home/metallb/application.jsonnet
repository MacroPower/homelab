local ns = import '../../../base/metallb/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='metallb',
  path='applications/environments/home/metallb',
  namespace=ns.metadata.name,
).withChart(
  name='metallb',
  repoURL='https://metallb.github.io/metallb',
  targetRevision='0.13.9',
  releaseName='metallb',
  values='../../../base/metallb/values.yaml'
)
