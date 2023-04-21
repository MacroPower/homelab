local external_secret = import '../../lib/external_secret.libsonnet';
local k = import '../../lib/k.libsonnet';
local ns = import '../linkerd-multicluster/namespace.libsonnet';

{
  new(name)::
    local secretKey = 'LINKERD_CLUSTER_CREDENTIALS_%s' % std.asciiUpper(name);
    external_secret.new(
      name=('cluster-credentials-%s' % name),
      namespace=ns.metadata.name,
      data=[
        external_secret.data(key=secretKey),
      ]
    ).withTemplate(
      type='mirror.linkerd.io/remote-kubeconfig',
      data={
        kubeconfig: '{{ .%s }}' % secretKey,
      },
    ),
}
