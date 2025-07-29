local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='securecodebox-config',
  path='applications/base/securecodebox-config',
  namespace=ns.metadata.name,
)
