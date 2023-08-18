local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='local-ai',
  path='applications/base/local-ai',
  namespace=ns.metadata.name,
).withChart(
  name='local-ai',
  repoURL='https://go-skynet.github.io/helm-charts/',
  targetRevision='2.1.1',
  releaseName='local-ai',
  values='values.yaml'
)
