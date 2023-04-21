local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('linkerd-multicluster') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'goldilocks.fairwinds.com/enabled': 'true',
  'linkerd.io/extension': 'multicluster',
  'pod-security.kubernetes.io/enforce': 'privileged',
})
