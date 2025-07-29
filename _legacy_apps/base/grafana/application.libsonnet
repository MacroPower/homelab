local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='grafana',
  path='applications/base/grafana',
  namespace=ns.metadata.name,
)
