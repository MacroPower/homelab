local external_secret = import '../../../lib/external_secret.libsonnet';
local ns = import '../namespace.libsonnet';

[
  external_secret.new(
    name='authentik-cluster-credentials',
    namespace=ns.metadata.name,
    data=[
      external_secret.data(key='AUTHENTIK_CLUSTER_COOKIE_DOMAIN'),
      external_secret.data(key='AUTHENTIK_CLUSTER_EXTERNAL_HOST'),
    ]
  ).withTemplate({
    'authentik.tfvars': |||
      authentik_cluster_cookie_domain = "{{ .AUTHENTIK_CLUSTER_COOKIE_DOMAIN }}"
      authentik_cluster_external_host = "{{ .AUTHENTIK_CLUSTER_EXTERNAL_HOST }}"
    |||,
  }),
]
