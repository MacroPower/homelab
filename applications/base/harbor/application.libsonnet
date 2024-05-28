local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='harbor',
  path='applications/base/harbor',
  namespace=ns.metadata.name,
).withChart(
  name='harbor',
  repoURL='https://helm.goharbor.io',
  targetRevision='1.14.2',
  releaseName='harbor',
  values='values.yaml'
).withIgnoreDifferences([
  {
    'group': 'apps',
    'kind': 'Deployment',
    'namespace': ns.metadata.name,
    'jsonPointers': [
      '/metadata/resourceVersion',
      '/metadata/generation',
      '/spec/template/metadata/annotations',
    ],
  },
  {
    'group': '',
    'kind': 'Secret',
    'namespace': ns.metadata.name,
    'name': 'harbor-core',
    'jsonPointers': [
      '/data',
    ],
  }
])
