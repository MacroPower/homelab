local app = import '../../../base/linkerd-multicluster/application.libsonnet';

app.withChartParams({
  'gateway.serviceAnnotations.metallb\\.universe\\.tf/allow-shared-ip': 'main',
})
