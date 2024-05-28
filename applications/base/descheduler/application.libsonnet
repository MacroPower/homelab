local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='descheduler',
  path='applications/base/descheduler',
  namespace=ns.metadata.name,
).withChart(
  name='descheduler',
  repoURL='https://kubernetes-sigs.github.io/descheduler/',
  targetRevision='0.30.0',
  releaseName='descheduler',
  values='values.yaml'
)
