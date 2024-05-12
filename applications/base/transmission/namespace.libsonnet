local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('transmission') +
k.core.v1.namespace.metadata.withLabelsMixin({})
