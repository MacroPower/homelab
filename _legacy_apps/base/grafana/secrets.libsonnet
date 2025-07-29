local external_secret = import '../../lib/external_secret.libsonnet';
local ns = import 'namespace.libsonnet';

[
  external_secret.new(
    name='grafana-credentials',
    namespace=ns.metadata.name,
    data=[
      external_secret.data(key='GRAFANA_ADMIN_USER'),
      external_secret.data(key='GRAFANA_ADMIN_PASS'),
    ]
  ),
]
