local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('k8up') +
k.core.v1.namespace.metadata.withLabelsMixin({}) +
k.core.v1.namespace.metadata.withAnnotationsMixin({})
