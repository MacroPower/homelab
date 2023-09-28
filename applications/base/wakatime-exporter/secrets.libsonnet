local external_secret = import '../../lib/external_secret.libsonnet';
local ns = import 'namespace.libsonnet';

[
  external_secret.new(
    name='wakatime-credentials',
    namespace=ns.metadata.name,
    data=[
      external_secret.data(key='WAKATIME_API_KEY'),
    ]
  ),
]
