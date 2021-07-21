local grafana = import 'grafana/grafana.libsonnet';
local gateway = import 'loki/gateway.libsonnet';
local loki = import 'loki/loki.libsonnet';
local minio = import 'minio.libsonnet';
local promtail = import 'promtail/promtail.libsonnet';

local klegacy = import 'ksonnet-util/kausal.libsonnet';
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
      namespace: 'loki',
      injectLabels: true,
      resourceDefaults: {},
      expectVersions: {},
    },
    data: loki + promtail + gateway + minio + grafana {
      _images+:: {
        grafana: 'grafana/grafana:latest',
      },

      _config+:: {
        local config = self,

        namespace: this.spec.namespace,
        htpasswd_contents: 'loki:$apr1$nGEyMWpT$/zyoiLpOpphU/zDb2NL3K.',

        storage_backend: 's3',
        boltdb_shipper_shared_store: 's3',
        s3_access_key: 'loki',
        s3_secret_access_key: 'XprhX1ygmIWNxJT85PoVtg5ITbEV4C',
        s3_address: 'minio.loki.svc.cluster.local:9000',
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
      },

      ingester_container+::
        klegacy.util.resourcesRequests(null, null),

      querier_container+::
        klegacy.util.resourcesRequests(null, null),

      compactor_container+::
        klegacy.util.resourcesRequests(null, null),

      ruler_container+::
        klegacy.util.resourcesRequests(null, null),
    },
  },
}
