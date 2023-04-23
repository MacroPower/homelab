local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('vertical-pod-autoscaler') +
k.core.v1.namespace.metadata.withAnnotationsMixin({
  'linkerd.io/inject': 'enabled',
})
