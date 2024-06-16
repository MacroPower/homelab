local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='nack',
  path='applications/base/nack',
  namespace='kube-system',
).withIgnoreDifferences([{
  'group': 'apiextensions.k8s.io',
  'kind': 'CustomResourceDefinition',
  'jsonPointers': [
    '/metadata/resourceVersion',
  ],
}])
