local app = import '../../../base/excoredns/application.libsonnet';

app.withChartParams({
  'domain': 'home.macro.network',
  'service.clusterIP': '10.132.0.11',
  'replicaCount': '1',
  'topologySpreadConstraints': null,
})
