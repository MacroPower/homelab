local kp =
  (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/main.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/external-metrics.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
      prometheus+: {
        thanos: {
          local cfg = self,
          version: 'v0.22.0',
          image: 'quay.io/thanos/thanos:' + cfg.version,
          objectStorageConfig: {
            key: 'thanos.yaml',
            name: 'thanos-objectstorage',
          },
        },
      },
    },
  };

local k = import 'lib/k.libsonnet';

function(apiServer='https://localhost:6443') {
  env: {
    local this = self,
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: 'environments/prometheus',
    },
    spec: {
      apiServer: apiServer,
      namespace: 'monitoring',
      injectLabels: true,
      resourceDefaults: {},
      expectVersions: {},
    },
    data:
      {
        ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
        for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
      } +
      // serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
      { 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
      { 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
      { 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
      { ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
      { ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
      { ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
      { ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
      { ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
      { ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
      { ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
      { ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) },
  },
}
