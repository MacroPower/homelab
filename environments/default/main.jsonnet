local k = import 'lib/k.libsonnet';

local minio = import 'minio.libsonnet';

function(apiServer='https://localhost:6443') {
  env: {
    local this = self,
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: 'environments/default',
    },
    spec: {
      apiServer: apiServer,
      namespace: 'default',
      injectLabels: true,
      resourceDefaults: {},
      expectVersions: {},
    },
    data: {
      monitoringNs: k.core.v1.namespace.new('monitoring'),

      minio: minio {
        _config+:: {
          bucketNames: ['loki-test', 'thanos-test'],
        },
      },
    },
  },
}
