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
          s3_access_key: 'minio-test',
          s3_secret_access_key: 'XprhX1ygmIWNxJT85PoVtg5ITbEV4C',
          s3_address: 'minio.monitoring.svc.cluster.local:9000',
          s3_bucket_names: ['loki-test', 'thanos-test'],
        },
      },
    },
  },
}
