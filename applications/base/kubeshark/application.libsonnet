local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kubeshark',
  path='applications/base/kubeshark',
  namespace=ns.metadata.name,
).withChart(
  name='kubeshark',
  repoURL='https://helm.kubeshark.co',
  targetRevision='51.0.18',
  releaseName='kubeshark',
  values='values.yaml'
)
