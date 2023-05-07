local app = import '../../lib/app.libsonnet';

app.new(
  name='prometheus',
  path='applications/base/prometheus',
  namespace='prometheus',
  renderer='kustomize',
)
