local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='servarr',
  path='applications/base/servarr',
  namespace=ns.metadata.name,
)
