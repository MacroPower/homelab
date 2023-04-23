local k = import '../../../lib/k.libsonnet';

k.core.v1.configMap.new('coredns-custom', data={
  'Corefile.override': |||
    forward . 10.0.0.1
  |||,
})
