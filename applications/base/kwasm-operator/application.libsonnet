local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kwasm-operator',
  path='applications/base/kwasm-operator',
  namespace=ns.metadata.name,
).withChart(
  name='kwasm-operator',
  repoURL='https://kwasm.sh/kwasm-operator/',
  targetRevision='0.2.3',
  releaseName='kwasm-operator',
  values='values.yaml'
)
