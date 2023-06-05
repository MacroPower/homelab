local external_secret = import '../../../lib/external_secret.libsonnet';
local ns = import '../namespace.libsonnet';

external_secret.new(
  name='authentik-cluster-credentials',
  namespace=ns.metadata.name,
  data=[
    external_secret.data(key='AUTHENTIK_CLUSTER_CREDENTIALS_HCLOUD'),
    external_secret.data(key='AUTHENTIK_CLUSTER_CREDENTIALS_SEEDBOX'),
  ]
).withTemplate({
  'authentik.tfvars': |||
    authentik_cluster_credentials_hcloud = <<-SkZyamdaPIoQzpvFoAFLc
    {{ .AUTHENTIK_CLUSTER_CREDENTIALS_HCLOUD }}
    SkZyamdaPIoQzpvFoAFLc

    authentik_cluster_credentials_seedbox = <<-GLsQqzPdFjzkQVQwPRdVL
    {{ .AUTHENTIK_CLUSTER_CREDENTIALS_SEEDBOX }}
    GLsQqzPdFjzkQVQwPRdVL
  |||,
})
