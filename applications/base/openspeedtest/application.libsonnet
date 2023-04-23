local app = import '../../lib/app.libsonnet';

app.new(
  name='openspeedtest',
  path='applications/base/openspeedtest',
  namespace='openspeedtest',
  renderer='kustomize',
)
