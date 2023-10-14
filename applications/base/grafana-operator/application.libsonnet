local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='grafana-operator',
  path='applications/base/grafana-operator',
  namespace=ns.metadata.name,
  renderer='kustomize',
)
