local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('rook-ceph') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'policy.jacobcolvin.com/drop-all-capabilities': 'false',
})
