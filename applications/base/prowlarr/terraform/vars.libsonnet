local external_secret = import '../../../lib/external_secret.libsonnet';
local ns = import '../namespace.libsonnet';

[
  external_secret.new(
    name='prowlarr-servarr-credentials',
    namespace=ns.metadata.name,
    data=[
      external_secret.data(key='RADARR_API_KEY'),
      external_secret.data(key='TRANSMISSION_MOVIES_RPC_PASSWORD'),
    ]
  ).withTemplate({
    'prowlarr.tfvars': |||
      radarr_api_key                   = "{{ .RADARR_API_KEY }}"
      transmission_movies_rpc_password = "{{ .TRANSMISSION_MOVIES_RPC_PASSWORD }}"
    |||,
  }),
]
