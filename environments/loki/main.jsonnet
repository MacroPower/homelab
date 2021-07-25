local gateway = import 'github.com/grafana/loki/production/ksonnet/loki/gateway.libsonnet';
local loki = import 'github.com/grafana/loki/production/ksonnet/loki/loki.libsonnet';
local promtail = import 'github.com/grafana/loki/production/ksonnet/promtail/promtail.libsonnet';

local klegacy = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
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
      namespace: 'monitoring',
      injectLabels: true,
      resourceDefaults: {},
      expectVersions: {},
    },
    data: loki + promtail + gateway {
      _config+:: {
        local config = self,

        namespace: this.spec.namespace,
        htpasswd_contents: 'loki:$apr1$nGEyMWpT$/zyoiLpOpphU/zDb2NL3K.',

        storage_backend: 's3',
        boltdb_shipper_shared_store: 's3',
        s3_access_key: 'minio-test',
        s3_secret_access_key: 'XprhX1ygmIWNxJT85PoVtg5ITbEV4C',
        s3_address: 'minio.default.svc.cluster.local:9000',
        s3_bucket_name: 'loki-test',
        s3_path_style: true,

        local pvc_class = 'hcloud-volumes',
        ingester_pvc_class: pvc_class,
        ruler_pvc_class: pvc_class,
        querier_pvc_class: pvc_class,
        compactor_pvc_class: pvc_class,

        promtail_config+: {
          clients: [{
            scheme:: 'http',
            hostname:: 'gateway.%(namespace)s.svc' % config,
            username:: 'loki',
            password:: 'kfYyyiqQxwohvJVBtrNn1rIXPguUlp',
            container_root_path:: '/var/lib/docker',
          }],
        },

        index_period_hours: 24,

        loki+: {
          schema_config+: {
            configs: [{
              from: '2020-11-04',
              store: 'boltdb-shipper',
              object_store: 's3',
              schema: 'v11',
              index: {
                prefix: '%s-index.' % config.namespace,
                period: '%dh' % config.index_period_hours,
              },
            }],
          },
        },

        replication_factor: 1,
        consul_replicas: 1,
        memcached_replicas: 1,
        queryFrontend+: {
          replicas: 1,
        },
      },

      ingester_container+::
        klegacy.util.resourcesRequests(null, null),

      querier_container+::
        klegacy.util.resourcesRequests(null, null),

      query_frontend_container+::
        klegacy.util.resourcesRequests(null, null),

      compactor_container+::
        klegacy.util.resourcesRequests(null, null),

      ruler_container+::
        klegacy.util.resourcesRequests(null, null),
    },
  },
}
