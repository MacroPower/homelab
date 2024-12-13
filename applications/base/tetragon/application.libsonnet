local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='tetragon',
  path='applications/base/tetragon',
  namespace=ns.metadata.name,
).withChart(
  name='tetragon',
  repoURL='https://helm.cilium.io/',
  targetRevision='1.3.0',
  releaseName='tetragon',
  values='values.yaml'
)
