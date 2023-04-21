local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('linkerd') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'goldilocks.fairwinds.com/enabled': 'true',
  'linkerd.io/is-control-plane': 'true',
  'linkerd.io/control-plane-ns': 'linkerd',
  'config.linkerd.io/admission-webhooks': 'disabled',
  'pod-security.kubernetes.io/enforce': 'privileged',
}) +
k.core.v1.namespace.metadata.withAnnotationsMixin({
  'linkerd.io/inject': 'disabled',
})
