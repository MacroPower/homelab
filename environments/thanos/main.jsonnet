local t = import 'github.com/thanos-io/kube-thanos/jsonnet/kube-thanos/thanos.libsonnet';

// For an example with every option and component, please check all.jsonnet

local commonConfig = {
  config+:: {
    local cfg = self,
    namespace: 'monitoring',
    version: 'v0.22.0',
    image: 'quay.io/thanos/thanos:' + cfg.version,
    objectStorageConfig: {
      name: 'thanos-objectstorage',
      key: 'thanos.yaml',
    },
    volumeClaimTemplate: {
      spec: {
        accessModes: ['ReadWriteOnce'],
        resources: {
          requests: {
            storage: '10Gi',
          },
        },
      },
    },
  },
};

local s = t.store(commonConfig.config {
  replicas: 2,
  serviceMonitor: true,
});

local q = t.query(commonConfig.config {
  replicas: 2,
  replicaLabels: ['prometheus_replica', 'rule_replica'],
  serviceMonitor: true,
});

local sc = t.sidecar(commonConfig.config {
  serviceMonitor: true,
  podLabelSelector: {
    app: 'prometheus',
  },
});

local finalQ = t.query(q.config {
  stores: [
    'dnssrv+_grpc._tcp.%s.%s.svc.cluster.local' % [service.metadata.name, service.metadata.namespace]
    for service in [sc.service, s.service]
  ],
});

function(apiServer='https://localhost:6443') {
  env: {
    local this = self,
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: 'environments/thanos',
    },
    spec: {
      apiServer: apiServer,
      namespace: 'monitoring',
      injectLabels: true,
      resourceDefaults: {},
      expectVersions: {},
    },
    data:
      { ['thanos-store-' + name]: s[name] for name in std.objectFields(s) } +
      { ['thanos-sidecar-' + name]: sc[name] for name in std.objectFields(sc) if sc[name] != null } +
      { ['thanos-query-' + name]: finalQ[name] for name in std.objectFields(finalQ) if finalQ[name] != null },
  },
}
