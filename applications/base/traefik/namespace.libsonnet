local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('traefik') +
k.core.v1.namespace.metadata.withAnnotationsMixin({
  'linkerd.io/inject': 'ingress',
})
