local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('linkerd-jaeger') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'goldilocks.fairwinds.com/enabled': 'true',
  'linkerd.io/extension': 'jaeger',
  'pod-security.kubernetes.io/enforce': 'privileged',
})
