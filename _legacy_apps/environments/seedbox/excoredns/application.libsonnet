local app = import '../../../base/excoredns/application.libsonnet';

app.withChartParams({
  'domain': 'seedbox.macro.network',
  'service.clusterIP': '10.43.0.11',
  'replicaCount': '1',
  'topologySpreadConstraints': null,
})
