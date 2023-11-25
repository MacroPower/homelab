local app = import '../../../base/argocd/application.libsonnet';

app.withChartParams({
  'redis-ha.enabled': 'false',
  'controller.replicas': '1',
  'server.replicas': '1',
  'repoServer.replicas': '1',
  'applicationSet.replicas': '1',
})
