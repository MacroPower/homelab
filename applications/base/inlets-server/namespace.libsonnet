local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('inlets') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'goldilocks.fairwinds.com/enabled': 'true',
})
