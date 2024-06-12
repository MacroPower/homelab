local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='ocis',
  path='applications/base/ocis',
  namespace=ns.metadata.name,
).withChart(
  name='ocis',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='1.0.0',
  releaseName='ocis',
  values='values.yaml'
).withIgnoreDifferences([
  {
    kind: 'Secret',
    jsonPointers: [
      '/data',
    ],
  },
  {
    kind: 'ConfigMap',
    jsonPointers: [
      '/data',
    ],
  },
])
