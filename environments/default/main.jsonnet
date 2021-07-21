local k = import 'lib/k.libsonnet';

function(apiServer='https://localhost:6443') {
  env: {
    local this = self,
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: 'environments/loki',
    },
    spec: {
      apiServer: apiServer,
      namespace: 'default',
      injectLabels: true,
      resourceDefaults: {},
      expectVersions: {},
    },
    data: {
      ns: k.core.v1.namespace.new('loki'),
    },
  },
}
