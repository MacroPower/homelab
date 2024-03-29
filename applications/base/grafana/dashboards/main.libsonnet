local k = import '../../lib/k.libsonnet';

local dashboard(name, data) =
  k.core.v1.configMap.new('grafana-dashboard-%s' % name, data={
    ['%s.json' % name]: data,
  }) + k.core.v1.configMap.metadata.withLabels({
    grafana_dashboard: '1',
  }) +
  k.core.v1.configMap.mixin.metadata.withAnnotations({
    'argocd.argoproj.io/sync-options': 'Replace=true',
  });

[
  dashboard(name='k8s-home', data=(importstr 'k8s-home.json')),
  dashboard(name='k8s-oversized-requests', data=(importstr 'k8s-oversized-requests.json')),
  dashboard(name='grafana-cloud-usage', data=(importstr 'grafana-cloud-usage.json')),
  dashboard(name='pfsense-net-quality', data=(importstr 'pfsense-net-quality.json')),
  dashboard(name='windows-node', data=(importstr 'windows-node.json')),
  dashboard(name='windows-node-processes', data=(importstr 'windows-node-processes.json')),

  // https://github.com/rfmoz/grafana-dashboards/tree/master/prometheus
  dashboard(name='node-exporter-full', data=(importstr 'node-exporter-full.json')),

  // https://grafana.com/grafana/dashboards/16523-windows-status-prometheus/
  dashboard(name='windows-summary', data=(importstr 'windows-summary.json')),

  // https://grafana.com/grafana/dashboards/14584-argocd/
  dashboard(name='argocd', data=(importstr 'argocd.json')),

  // https://github.com/onedr0p/exportarr/tree/master/examples/grafana
  dashboard(name='servarr', data=(importstr 'servarr.json')),

  // https://github.com/dotdc/grafana-dashboards-kubernetes
  dashboard(name='k8s-system-api-server', data=(importstr 'k8s-system-api-server.json')),
  dashboard(name='k8s-system-coredns', data=(importstr 'k8s-system-coredns.json')),
  dashboard(name='k8s-views-global', data=(importstr 'k8s-views-global.json')),
  dashboard(name='k8s-views-namespaces', data=(importstr 'k8s-views-namespaces.json')),
  dashboard(name='k8s-views-nodes', data=(importstr 'k8s-views-nodes.json')),
  dashboard(name='k8s-views-pods', data=(importstr 'k8s-views-pods.json')),
]
