local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('homepage') +
k.core.v1.namespace.metadata.withAnnotationsMixin({
  'linkerd.io/inject': 'enabled',
})
