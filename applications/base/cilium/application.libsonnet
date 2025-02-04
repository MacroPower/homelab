local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='cilium',
  path='applications/base/cilium',
  namespace='cilium',
).withChart(
  name='cilium',
  repoURL='https://helm.cilium.io',
  targetRevision='1.17.0',
  releaseName='cilium',
  values='values.yaml'
).withIgnoreDifferences([
  {
    kind: 'Secret',
    name: 'cilium-ca',
    namespace: 'cilium',
    jsonPointers: [
      '/data',
    ],
  },
])
