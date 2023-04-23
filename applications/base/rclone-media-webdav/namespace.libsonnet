local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('media-webdav') +
k.core.v1.namespace.metadata.withAnnotationsMixin({
  'linkerd.io/inject': 'enabled',
})
