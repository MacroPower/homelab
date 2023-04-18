local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('goldilocks') +
k.core.v1.namespace.metadata.withLabelsMixin({}) +
k.core.v1.namespace.metadata.withAnnotationsMixin({
  'linkerd.io/inject': 'enabled',
})
