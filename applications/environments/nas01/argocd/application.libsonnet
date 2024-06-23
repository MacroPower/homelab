local app = import '../../../base/argocd/application.libsonnet';

app.withChartParams({
  'controller.replicas': '1',
  'server.replicas': '1',
  'repoServer.replicas': '1',
  'applicationSet.replicas': '1',
})
