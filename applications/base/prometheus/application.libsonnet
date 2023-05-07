local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='prometheus',
  path='applications/base/prometheus',
  namespace=ns.metadata.name,
  renderer='kustomize',
)
