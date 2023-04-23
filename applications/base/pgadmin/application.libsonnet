local app = import '../../lib/app.libsonnet';

app.new(
  name='pgadmin4',
  path='applications/base/pgadmin',
  namespace='pgadmin',
  renderer='kustomize',
)
