local k = import '../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('adguard-home-config', data={
    'AdGuardHome.yaml': (importstr 'AdGuardHome.yaml'),
  }),
]
