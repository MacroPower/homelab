local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kyverno-policies',
  path='applications/base/kyverno-policies',
  namespace=ns.metadata.name,
  renderer='kustomize',
).withIgnoreDifferences([{
  'group': 'kyverno.io',
  'kind': 'ClusterPolicy',
  'jsonPointers': [
    '/status/autogen',
    '/metadata/resourceVersion',
  ],
}])
