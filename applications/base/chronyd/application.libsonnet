local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='chronyd',
  path='applications/base/chronyd',
  namespace=ns.metadata.name,
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.2.0',
  releaseName='chronyd',
  values='values.yaml'
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.2.0',
  releaseName='chronyd-agent',
  values='values-agent.yaml'
)
