local external_secret = import '../../lib/external_secret.libsonnet';
local ns = import 'namespace.libsonnet';

[
  external_secret.new(
    name='twitch-cookie',
    namespace=ns.metadata.name,
    data=[
      external_secret.data(
        key='Cookie.pkl',
        remoteKey='TWITCH_COOKIE',
        decodingStrategy='Base64',
      ),
    ]
  ),
]
