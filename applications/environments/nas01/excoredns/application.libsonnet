local app = import '../../../base/excoredns/application.libsonnet';

app.withChartParams({
  'domain': 'nas01.home.macro.network',
  'service.clusterIP': '10.133.0.11',
  'replicaCount': '1',
  'topologySpreadConstraints': null,
})
